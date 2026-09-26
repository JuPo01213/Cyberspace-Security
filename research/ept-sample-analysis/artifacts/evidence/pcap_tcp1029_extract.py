import glob
import ipaddress
import os
import struct


def parse_dns_name(pkt, off):
    labels = []
    seen = set()
    while off < len(pkt):
        if off in seen:
            break
        seen.add(off)
        n = pkt[off]
        if n == 0:
            return '.'.join(labels), off + 1
        if (n & 0xc0) == 0xc0:
            if off + 1 >= len(pkt):
                return '.'.join(labels), off + 2
            ptr = ((n & 0x3f) << 8) | pkt[off + 1]
            tail, _ = parse_dns_name(pkt, ptr)
            if tail:
                labels.append(tail)
            return '.'.join(labels), off + 2
        off += 1
        if off + n > len(pkt):
            return '.'.join(labels), off
        labels.append(pkt[off:off + n].decode('ascii', 'replace'))
        off += n
    return '.'.join(labels), off


def ipv4_payload(pkt, linktype):
    if linktype == 1:
        if len(pkt) < 14:
            return None
        et = struct.unpack_from('!H', pkt, 12)[0]
        off = 14
        while et in (0x8100, 0x88a8, 0x9100):
            if len(pkt) < off + 4:
                return None
            et = struct.unpack_from('!H', pkt, off + 2)[0]
            off += 4
        if et != 0x0800:
            return None
        return pkt[off:]
    if linktype in (101, 228):
        return pkt
    if linktype == 113:
        if len(pkt) < 16:
            return None
        proto = struct.unpack_from('!H', pkt, 14)[0]
        if proto != 0x0800:
            return None
        return pkt[16:]
    return None


def ascii_preview(data):
    return ''.join(chr(x) if 32 <= x <= 126 else '.' for x in data[:160])


def parse_file(path):
    data = open(path, 'rb').read()
    if len(data) < 24:
        return
    magic = data[:4]
    if magic == b'\xd4\xc3\xb2\xa1':
        endian = '<'
    elif magic == b'\xa1\xb2\xc3\xd4':
        endian = '>'
    else:
        print(os.path.basename(path), 'unsupported magic', magic.hex())
        return
    vmaj, vmin, tz, sigfigs, snaplen, linktype = struct.unpack_from(endian + 'HHiiii', data, 4)
    off = 24
    packets = 0
    tcp1029 = []
    dns_hits = []
    while off + 16 <= len(data):
        ts_sec, ts_usec, incl, orig = struct.unpack_from(endian + 'IIII', data, off)
        off += 16
        pkt = data[off:off + incl]
        off += incl
        packets += 1
        ip = ipv4_payload(pkt, linktype)
        if not ip or len(ip) < 20 or (ip[0] >> 4) != 4:
            continue
        ihl = (ip[0] & 0x0f) * 4
        total_len = struct.unpack_from('!H', ip, 2)[0]
        ip_end = min(len(ip), total_len)
        src = str(ipaddress.ip_address(ip[12:16]))
        dst = str(ipaddress.ip_address(ip[16:20]))
        proto = ip[9]
        if b'hwid001' in ip.lower():
            dns_hits.append((src, dst, ip[:ip_end]))
        if proto == 6 and len(ip) >= ihl + 20:
            t = ihl
            sp, dp, seq, ack, off_flags = struct.unpack_from('!HHIIH', ip, t)
            thl = ((off_flags >> 12) & 0xf) * 4
            flags = off_flags & 0x1ff
            payload = ip[t + thl:ip_end] if t + thl <= ip_end else b''
            if sp == 1029 or dp == 1029:
                tcp1029.append((ts_sec, ts_usec, src, sp, dst, dp, seq, ack, flags, payload))
    print('\n' + os.path.basename(path), 'packets=', packets, 'linktype=', linktype,
          'tcp1029_packets=', len(tcp1029), 'tcp1029_payload=', sum(len(x[-1]) for x in tcp1029),
          'dns_name_hits=', len(dns_hits))
    if dns_hits:
        print('  DNS/packet hwid001 hits:', len(dns_hits))
    if not tcp1029:
        return
    flows = {}
    for item in tcp1029:
        flow = (item[2], item[3], item[4], item[5])
        flows.setdefault(flow, []).append(item)
    for flow, items in flows.items():
        items.sort(key=lambda x: (x[6], x[0], x[1]))
        # Keep first-seen bytes by sequence number, which removes common retransmits.
        assembled = bytearray()
        seen_ranges = []
        for item in items:
            seq = item[6]
            payload = item[-1]
            if not payload:
                continue
            if not seen_ranges:
                assembled.extend(payload)
                seen_ranges.append((seq, seq + len(payload)))
                continue
            # append only data beyond the furthest assembled sequence
            end = seq + len(payload)
            furthest = max(x[1] for x in seen_ranges)
            if end > furthest:
                start = max(0, furthest - seq)
                assembled.extend(payload[start:])
                seen_ranges.append((seq + start, end))
        print('  flow', flow, 'packets=', len(items), 'assembled=', len(assembled))
        if assembled:
            print('    hex=', bytes(assembled[:512]).hex())
            print('    ascii=', ascii_preview(bytes(assembled)))
            for item in items:
                if item[-1]:
                    print('    packet', item[2], item[3], '->', item[4], item[5],
                          'seq=', item[6], 'len=', len(item[-1]), 'hex=', item[-1][:128].hex())


for path in sorted(glob.glob('artifacts/captures/pcap/*')):
    try:
        parse_file(path)
    except Exception as exc:
        print(os.path.basename(path), 'ERROR', repr(exc))
