
/* WARNING: Function: __security_check_cookie replaced with injection: security_check_cookie */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 FUN_140791c30(void)

{
  longlong lVar1;
  longlong lVar2;
  ushort uVar3;
  uint uVar4;
  int iVar5;
  uint uVar6;
  undefined8 uVar7;
  char *pcVar8;
  wchar_t *pwVar9;
  ulonglong uVar10;
  undefined8 unaff_RBX;
  longlong lVar11;
  longlong *plVar12;
  longlong *plVar13;
  undefined1 *puVar14;
  undefined1 *puVar15;
  wchar_t *pwVar16;
  longlong alStack_f8 [5];
  undefined1 auStack_c8 [32];
  longlong local_a8;
  longlong local_a0;
  longlong local_98;
  longlong local_88 [2];
  undefined8 local_78;
  ulonglong local_70;
  ulonglong local_68;
  undefined8 local_60;
  longlong lStack_58;
  ulonglong local_50;
  undefined2 local_48;
  undefined6 uStack_46;
  undefined8 local_38;
  ulonglong local_30;
  ulonglong local_28;
  
  local_28 = (ulonglong)auStack_c8 ^ 0x2b992ddfa232;
  uVar6 = 0;
  plVar13 = (longlong *)auStack_c8;
  if ((int)_DAT_141154d10 < 0) {
    plVar12 = (longlong *)&stack0xffffffffffffff30;
    alStack_f8[4] = 0x140791c78;
    uVar4 = func_0x00014157bdf8("C:\\Windows\\System32");
    if ((uVar4 == 0xffffffff) || ((uVar4 & 0x10) == 0)) {
      pcVar8 = "<HOST_PATH>\<DIR>";
      alStack_f8[4] = 0x140791c8d;
      func_0x0001417510aa();
      _DAT_141154d10 = in(0x83);
      alStack_f8[4] = *(undefined8 *)((longlong)pcVar8 * 2 + -0x58);
      plVar12 = alStack_f8 + 4;
      pcVar8 = (char *)((ulonglong)_DAT_141154d10 + 1);
      *pcVar8 = *pcVar8 + (char)((ulonglong)unaff_RBX >> 8);
      plVar13 = alStack_f8 + 4;
      if (*pcVar8 != '\0') goto LAB_140791ca5;
    }
    plVar13 = plVar12;
    _DAT_141154d10 = uVar6;
  }
LAB_140791ca5:
  pwVar16 = L"C:\\Windows\\System32\\Hardware.ini";
  pwVar9 = L"C:\\Windows\\System32\\Hardware.ini";
  if (_DAT_141154d10 == 1) {
    pwVar9 = L"<HOST_PATH>\<DIR>rdware.ini";
  }
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791cc2;
  uVar4 = func_0x0001417c4867(pwVar9);
  if ((uVar4 != 0xffffffff) && ((uVar4 & 0x10) == 0)) {
    uVar7 = 1;
    puVar15 = (undefined1 *)plVar13;
    goto LAB_140792d39;
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791cfe;
  FUN_1407ace80(local_88,L"baseboard get SerialNumber",0x1a);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791d13;
  uVar7 = FUN_140790fc0(&local_68,local_88,L"SerialNumber");
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791d20;
  uVar7 = FUN_140791470(&local_48,uVar7);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791d30;
  FUN_140791b20(L"BoardId",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar1 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792d6d;
        FUN_1407b8bd4(lVar1,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140791d71;
    thunk_FUN_1407c68b0();
  }
  local_38 = 0;
  local_30 = 7;
  local_48 = 0;
  if (local_68 != 0) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140791d94;
    FUN_1407af540(local_68,local_60);
    uVar10 = lStack_58 - local_68 & 0xffffffffffffffe0;
    if (0xfff < uVar10) {
      lVar1 = *(longlong *)(local_68 - 8);
      if (0x1f < (local_68 - lVar1) - 8) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792d73;
        FUN_1407b8bd4(lVar1,uVar10 + 0x27);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140791dcd;
    thunk_FUN_1407c68b0();
    local_68 = 0;
    local_60 = 0;
    lStack_58 = 0;
  }
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar1 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792d79;
        FUN_1407b8bd4(lVar1,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140791e19;
    thunk_FUN_1407c68b0();
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791e44;
  FUN_1407ace80(local_88,L"csproduct get UUID",0x12);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791e59;
  uVar7 = FUN_140790fc0(&local_68,local_88,L"UUID");
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791e66;
  uVar7 = FUN_140791470(&local_48,uVar7);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791e76;
  FUN_140791b20(L"Uuid",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar1 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792d7f;
        FUN_1407b8bd4(lVar1,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140791eb7;
    thunk_FUN_1407c68b0();
  }
  local_38 = 0;
  local_30 = 7;
  local_48 = 0;
  if (local_68 != 0) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140791eda;
    FUN_1407af540(local_68,local_60);
    uVar10 = lStack_58 - local_68 & 0xffffffffffffffe0;
    if (0xfff < uVar10) {
      lVar1 = *(longlong *)(local_68 - 8);
      if (0x1f < (local_68 - lVar1) - 8) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792d85;
        FUN_1407b8bd4(lVar1,uVar10 + 0x27);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140791f13;
    thunk_FUN_1407c68b0();
    local_68 = 0;
    local_60 = 0;
    lStack_58 = 0;
  }
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar1 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792d8b;
        FUN_1407b8bd4(lVar1,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140791f5f;
    thunk_FUN_1407c68b0();
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791f8a;
  FUN_1407ace80(local_88,L"csproduct get Name",0x12);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791f9f;
  uVar7 = FUN_140790fc0(&local_68,local_88,L"Name");
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791fac;
  uVar7 = FUN_140791470(&local_48,uVar7);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140791fbc;
  FUN_140791b20(L"BrandModel",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar1 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792d91;
        FUN_1407b8bd4(lVar1,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140791ffd;
    thunk_FUN_1407c68b0();
  }
  local_38 = 0;
  local_30 = 7;
  local_48 = 0;
  if (local_68 != 0) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792020;
    FUN_1407af540(local_68,local_60);
    uVar10 = lStack_58 - local_68 & 0xffffffffffffffe0;
    if (0xfff < uVar10) {
      lVar1 = *(longlong *)(local_68 - 8);
      if (0x1f < (local_68 - lVar1) - 8) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792d97;
        FUN_1407b8bd4(lVar1,uVar10 + 0x27);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792059;
    thunk_FUN_1407c68b0();
    local_68 = 0;
    local_60 = 0;
    lStack_58 = 0;
  }
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar1 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792d9d;
        FUN_1407b8bd4(lVar1,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407920a5;
    thunk_FUN_1407c68b0();
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407920d0;
  FUN_1407ace80(local_88,L"bios get SerialNumber",0x15);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407920e5;
  uVar7 = FUN_140790fc0(&local_68,local_88,L"SerialNumber");
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407920f2;
  uVar7 = FUN_140791470(&local_48,uVar7);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792102;
  FUN_140791b20(L"BiosSerial",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar1 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792da3;
        FUN_1407b8bd4(lVar1,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792143;
    thunk_FUN_1407c68b0();
  }
  local_38 = 0;
  local_30 = 7;
  local_48 = 0;
  if (local_68 != 0) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792166;
    FUN_1407af540(local_68,local_60);
    uVar10 = lStack_58 - local_68 & 0xffffffffffffffe0;
    if (0xfff < uVar10) {
      lVar1 = *(longlong *)(local_68 - 8);
      if (0x1f < (local_68 - lVar1) - 8) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792da9;
        FUN_1407b8bd4(lVar1,uVar10 + 0x27);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x14079219f;
    thunk_FUN_1407c68b0();
    local_68 = 0;
    local_60 = 0;
    lStack_58 = 0;
  }
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar1 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792daf;
        FUN_1407b8bd4(lVar1,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407921eb;
    thunk_FUN_1407c68b0();
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792216;
  FUN_1407ace80(local_88,L"diskdrive get SerialNumber",0x1a);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x14079222b;
  uVar7 = FUN_140790fc0(&local_68,local_88,L"SerialNumber");
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792238;
  uVar7 = FUN_140790de0(&local_48,uVar7);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792248;
  FUN_140791b20(L"DiskSerials",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar1 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792db5;
        FUN_1407b8bd4(lVar1,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792289;
    thunk_FUN_1407c68b0();
  }
  local_38 = 0;
  local_30 = 7;
  local_48 = 0;
  if (local_68 != 0) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407922ac;
    FUN_1407af540(local_68,local_60);
    uVar10 = lStack_58 - local_68 & 0xffffffffffffffe0;
    if (0xfff < uVar10) {
      lVar1 = *(longlong *)(local_68 - 8);
      if (0x1f < (local_68 - lVar1) - 8) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792dbb;
        FUN_1407b8bd4(lVar1,uVar10 + 0x27);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407922e5;
    thunk_FUN_1407c68b0();
    local_68 = 0;
    local_60 = 0;
    lStack_58 = 0;
  }
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar1 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792dc1;
        FUN_1407b8bd4(lVar1,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792331;
    thunk_FUN_1407c68b0();
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x14079235c;
  FUN_1407ace80(local_88,L"cpu get ProcessorId",0x13);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792371;
  uVar7 = FUN_140790fc0(&local_68,local_88,L"ProcessorId");
  *(undefined8 *)((longlong)plVar13 + -8) = 0x14079237e;
  uVar7 = FUN_140790de0(&local_48,uVar7);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x14079238e;
  FUN_140791b20(L"CpuIds",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar1 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792dc7;
        FUN_1407b8bd4(lVar1,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407923cf;
    thunk_FUN_1407c68b0();
  }
  local_38 = 0;
  local_30 = 7;
  local_48 = 0;
  if (local_68 != 0) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407923f2;
    FUN_1407af540(local_68,local_60);
    uVar10 = lStack_58 - local_68 & 0xffffffffffffffe0;
    if (0xfff < uVar10) {
      lVar1 = *(longlong *)(local_68 - 8);
      if (0x1f < (local_68 - lVar1) - 8) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792dcd;
        FUN_1407b8bd4(lVar1,uVar10 + 0x27);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x14079242b;
    thunk_FUN_1407c68b0();
    local_68 = 0;
    local_60 = 0;
    lStack_58 = 0;
  }
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar1 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792dd3;
        FUN_1407b8bd4(lVar1,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792477;
    thunk_FUN_1407c68b0();
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407924a2;
  FUN_1407ace80(local_88,L"cpu get SerialNumber",0x14);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407924b7;
  uVar7 = FUN_140790fc0(&local_68,local_88,L"SerialNumber");
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407924c4;
  uVar7 = FUN_140790de0(&local_48,uVar7);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407924d4;
  FUN_140791b20(L"CpuSerials",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar1 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792dd9;
        FUN_1407b8bd4(lVar1,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792515;
    thunk_FUN_1407c68b0();
  }
  local_38 = 0;
  local_30 = 7;
  local_48 = 0;
  if (local_68 != 0) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792538;
    FUN_1407af540(local_68,local_60);
    uVar10 = lStack_58 - local_68 & 0xffffffffffffffe0;
    if (0xfff < uVar10) {
      lVar1 = *(longlong *)(local_68 - 8);
      if (0x1f < (local_68 - lVar1) - 8) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792ddf;
        FUN_1407b8bd4(lVar1,uVar10 + 0x27);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792571;
    thunk_FUN_1407c68b0();
    local_68 = 0;
    local_60 = 0;
    lStack_58 = 0;
  }
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar1 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792de5;
        FUN_1407b8bd4(lVar1,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407925bd;
    thunk_FUN_1407c68b0();
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407925e8;
  FUN_1407ace80(local_88,L"path Win32_VideoController get Name",0x23);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407925fd;
  uVar7 = FUN_140790fc0(&local_68,local_88,L"Name");
  *(undefined8 *)((longlong)plVar13 + -8) = 0x14079260a;
  uVar7 = FUN_140790de0(&local_48,uVar7);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x14079261a;
  FUN_140791b20(L"Gpus",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar1 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792deb;
        FUN_1407b8bd4(lVar1,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x14079265b;
    thunk_FUN_1407c68b0();
  }
  local_38 = 0;
  local_30 = 7;
  local_48 = 0;
  if (local_68 != 0) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x14079267e;
    FUN_1407af540(local_68,local_60);
    uVar10 = lStack_58 - local_68 & 0xffffffffffffffe0;
    if (0xfff < uVar10) {
      lVar1 = *(longlong *)(local_68 - 8);
      if (0x1f < (local_68 - lVar1) - 8) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792df1;
        FUN_1407b8bd4(lVar1,uVar10 + 0x27);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407926b7;
    thunk_FUN_1407c68b0();
    local_68 = 0;
    local_60 = 0;
    lStack_58 = 0;
  }
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar1 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792df7;
        FUN_1407b8bd4(lVar1,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792703;
    thunk_FUN_1407c68b0();
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x14079272e;
  FUN_1407ace80(local_88,L"memorychip get SerialNumber",0x1b);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792743;
  uVar7 = FUN_140790fc0(&local_68,local_88,L"SerialNumber");
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792750;
  uVar7 = FUN_140790de0(&local_48,uVar7);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792760;
  FUN_140791b20(L"MemorySerials",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar1 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792dfd;
        FUN_1407b8bd4(lVar1,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407927a1;
    thunk_FUN_1407c68b0();
  }
  local_38 = 0;
  local_30 = 7;
  local_48 = 0;
  if (local_68 != 0) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407927c4;
    FUN_1407af540(local_68,local_60);
    uVar10 = lStack_58 - local_68 & 0xffffffffffffffe0;
    if (0xfff < uVar10) {
      lVar1 = *(longlong *)(local_68 - 8);
      if (0x1f < (local_68 - lVar1) - 8) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792e03;
        FUN_1407b8bd4(lVar1,uVar10 + 0x27);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407927fd;
    thunk_FUN_1407c68b0();
    local_68 = 0;
    local_60 = 0;
    lStack_58 = 0;
  }
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar1 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792e09;
        FUN_1407b8bd4(lVar1,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792849;
    thunk_FUN_1407c68b0();
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792874;
  FUN_1407ace80(local_88,
                L"path Win32_NetworkAdapterConfiguration where IPEnabled=True get MACAddress",0x4a);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792889;
  uVar7 = FUN_140790fc0(&local_68,local_88,L"MACAddress");
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792896;
  uVar7 = FUN_140790de0(&local_48,uVar7);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407928a6;
  FUN_140791b20(L"Macs",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar1 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792e0f;
        FUN_1407b8bd4(lVar1,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x1407928e7;
    thunk_FUN_1407c68b0();
  }
  local_38 = 0;
  local_30 = 7;
  local_48 = 0;
  if (local_68 != 0) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x14079290a;
    FUN_1407af540(local_68,local_60);
    uVar10 = lStack_58 - local_68 & 0xffffffffffffffe0;
    if (0xfff < uVar10) {
      lVar1 = *(longlong *)(local_68 - 8);
      if (0x1f < (local_68 - lVar1) - 8) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792e15;
        FUN_1407b8bd4(lVar1,uVar10 + 0x27);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792943;
    thunk_FUN_1407c68b0();
    local_68 = 0;
    local_60 = 0;
    lStack_58 = 0;
  }
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar1 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792e1b;
        FUN_1407b8bd4(lVar1,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x14079298f;
    thunk_FUN_1407c68b0();
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407929ba;
  FUN_1407ace80(local_88,
                L"path Win32_NetworkAdapterConfiguration where IPEnabled=True get DefaultIPGateway",
                0x50);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x1407929cf;
  FUN_140790fc0(&local_a8,local_88,L"DefaultIPGateway");
  lVar11 = local_a8;
  lVar1 = local_a0;
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar1 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792e21;
        FUN_1407b8bd4(lVar1,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792a10;
    thunk_FUN_1407c68b0();
    lVar11 = local_a8;
    lVar1 = local_a0;
  }
  for (; lVar11 != lVar1; lVar11 = lVar11 + 0x20) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792a29;
    uVar7 = FUN_1407abfb0(local_88,lVar11);
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792a35;
    uVar7 = FUN_1407915e0(&local_48,uVar7);
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792a40;
    FUN_1407abed0(lVar11,uVar7);
    if (7 < local_30) {
      if (0xfff < local_30 * 2 + 2) {
        lVar2 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
        if (0x1f < (CONCAT62(uStack_46,local_48) - lVar2) - 8U) {
                    /* WARNING: Subroutine does not return */
          *(undefined **)((longlong)plVar13 + -8) = &UNK_140792e27;
          FUN_1407b8bd4(lVar2,local_30 * 2 + 0x29);
        }
      }
      *(undefined8 *)((longlong)plVar13 + -8) = 0x140792a80;
      thunk_FUN_1407c68b0();
    }
  }
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792a93;
  uVar7 = FUN_140790de0(&local_48,&local_a8);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792aa3;
  FUN_140791b20(L"Gateways",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar2 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar2) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792e2d;
        FUN_1407b8bd4(lVar2,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792ae4;
    thunk_FUN_1407c68b0();
  }
  local_78 = 0;
  local_70 = 7;
  local_88[0] = 0;
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792b0f;
  FUN_1407ace80(local_88,L"ipconfig /all",0xd);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792b23;
  uVar7 = FUN_140790630(&local_68,local_88,5000);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792b30;
  uVar7 = FUN_1407919b0(&local_48,uVar7);
  *(undefined8 *)((longlong)plVar13 + -8) = 0x140792b40;
  FUN_140791b20(L"Duid",uVar7);
  if (7 < local_30) {
    if (0xfff < local_30 * 2 + 2) {
      lVar2 = *(longlong *)(CONCAT62(uStack_46,local_48) + -8);
      if (0x1f < (CONCAT62(uStack_46,local_48) - lVar2) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792e33;
        FUN_1407b8bd4(lVar2,local_30 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792b81;
    thunk_FUN_1407c68b0();
  }
  local_38 = 0;
  local_30 = 7;
  local_48 = 0;
  if (7 < local_50) {
    if (0xfff < local_50 * 2 + 2) {
      lVar2 = *(longlong *)(local_68 - 8);
      if (0x1f < (local_68 - lVar2) - 8) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792e39;
        FUN_1407b8bd4(lVar2,local_50 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792bd2;
    thunk_FUN_1407c68b0();
  }
  lStack_58 = 0;
  local_50 = 7;
  local_68 = local_68 & 0xffffffffffff0000;
  if (7 < local_70) {
    if (0xfff < local_70 * 2 + 2) {
      lVar2 = *(longlong *)(local_88[0] + -8);
      if (0x1f < (local_88[0] - lVar2) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)((longlong)plVar13 + -8) = &UNK_140792e3f;
        FUN_1407b8bd4(lVar2,local_70 * 2 + 0x29);
      }
    }
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792c23;
    thunk_FUN_1407c68b0();
  }
  puVar15 = (undefined1 *)plVar13;
  if ((int)_DAT_141154d10 < 0) {
    *(undefined8 *)((longlong)plVar13 + -8) = 0x140792c39;
    uVar3 = func_0x00014161dabe("C:\\Windows\\System32");
    if ((uVar3 == 0xffff) || (puVar14 = (undefined1 *)plVar13, (uVar3 & 0x10) == 0)) {
      *(longlong *)((longlong)plVar13 + -8) = lVar1;
      *(undefined8 *)((longlong)plVar13 + -0x10) = 0x140792c50;
      uVar4 = func_0x00014178a6fe("<HOST_PATH>\<DIR>");
      puVar14 = (undefined1 *)((longlong)plVar13 + -8);
      if ((uVar4 != 0xffffffff) &&
         (puVar14 = (undefined1 *)((longlong)plVar13 + -8),
         puVar15 = (undefined1 *)((longlong)plVar13 + -8), _DAT_141154d10 = 1, (uVar4 & 0x10) != 0))
      goto LAB_140792c67;
    }
    puVar15 = puVar14;
    _DAT_141154d10 = 0;
  }
LAB_140792c67:
  pwVar9 = L"C:\\Windows\\System32\\Hardware.ini";
  if (_DAT_141154d10 == 1) {
    pwVar9 = L"<HOST_PATH>\<DIR>rdware.ini";
  }
  *(undefined8 *)(puVar15 + -8) = 0x140792c8b;
  func_0x00014144201a(L"Meta",L"Version",&DAT_140f8eb2c,pwVar9);
  iVar5 = in(0x8b);
  uVar4 = iVar5 + 0x9c207e;
  puVar14 = puVar15;
  if ((int)uVar4 < 0) {
    *(ulonglong *)(puVar15 + -8) = (ulonglong)uVar4;
    *(undefined8 *)(puVar15 + -0x10) = 0x140792ca3;
    uVar4 = func_0x0001419b98bf("C:\\Windows\\System32");
    if ((uVar4 == 0xffffffff) || ((uVar4 & 0x10) == 0)) {
      *(undefined8 *)(puVar15 + -0x10) = 0x140792cb8;
      uVar10 = func_0x000141421310("<HOST_PATH>\<DIR>");
      puVar14 = puVar15 + -8;
      uVar4 = 1;
      _DAT_141154d10 = 1;
      if ((uVar10 & 0x10) != 0) goto LAB_140792cd0;
    }
    puVar14 = puVar15 + -8;
    uVar4 = uVar6;
    _DAT_141154d10 = uVar6;
  }
LAB_140792cd0:
  if (uVar4 == 1) {
    pwVar16 = L"<HOST_PATH>\<DIR>rdware.ini";
  }
  *(longlong *)(puVar14 + -8) = lVar11;
  *(undefined8 *)(puVar14 + -0x10) = 0x140792ce0;
  uVar6 = func_0x0001417e5b88(pwVar16);
  if ((uVar6 == 0xffffffff) || ((uVar6 & 0x10) != 0)) {
    uVar7 = 0;
  }
  else {
    uVar7 = 1;
  }
  puVar15 = puVar14 + -8;
  if (local_a8 != 0) {
    *(undefined8 *)(puVar14 + -0x10) = 0x140792d01;
    FUN_1407af540(local_a8,local_a0);
    uVar10 = local_98 - local_a8 & 0xffffffffffffffe0;
    if (0xfff < uVar10) {
      lVar1 = *(longlong *)(local_a8 + -8);
      if (0x1f < (local_a8 - lVar1) - 8U) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)(puVar14 + -0x10) = &UNK_140792d67;
        FUN_1407b8bd4(lVar1,uVar10 + 0x27);
      }
    }
    *(undefined8 *)(puVar14 + -0x10) = 0x140792d36;
    thunk_FUN_1407c68b0();
    puVar15 = puVar14 + -8;
  }
LAB_140792d39:
  *(undefined8 *)(puVar15 + -8) = 0x140792d45;
  return uVar7;
}

