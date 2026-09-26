// ==== FUN_1407a3080 @ 1407a3080 ====

/* WARNING: Function: __security_check_cookie replaced with injection: security_check_cookie */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 FUN_1407a3080(void)

{
  char cVar1;
  int iVar2;
  undefined8 uVar3;
  undefined1 auStack_3a8 [32];
  undefined8 local_388;
  undefined4 local_378 [4];
  undefined1 local_368 [80];
  undefined1 local_318 [512];
  undefined1 local_118 [256];
  ulonglong local_18;
  
  local_18 = _DAT_140f9e010 ^ (ulonglong)auStack_3a8;
  FUN_14078fc90(0x140f92508);
  if ((((_DAT_141154ced == 1) && (_DAT_141154cf1 == 1)) && (DAT_141154ae7 != '\0')) &&
     (_DAT_141154ce9 != 0)) {
    cVar1 = '\x01';
  }
  else {
    cVar1 = '\0';
  }
  FUN_1407b4700(local_318,0,0x100);
  FUN_1407adb40(local_318,0x140f8e2c0,0x140f92520,cVar1);
  FUN_14078fc90(local_318);
  if (cVar1 == '\0') {
    uVar3 = 0;
  }
  else {
    iVar2 = FUN_1403b34d0(0x140f92550,30000,0);
    FUN_1407b4700(local_318,0,0x200);
    local_388 = FUN_14078fad0(iVar2);
    FUN_1407adae0(local_318,0x140f8e2a8,0x140f92640,iVar2);
    FUN_14078fc90(local_318);
    if (iVar2 == 0) {
      FUN_1405a03d0();
      FUN_1403b3280(0x140f92688,0x405);
      FUN_14078fc90(0x140f92698);
      iVar2 = FUN_1403c47e0(local_368);
      FUN_1407b4700(local_318,0,0x200);
      local_388 = FUN_14078fad0(iVar2);
      FUN_1407adae0(local_318,0x140f8e2a8,0x140f926c8,iVar2);
      FUN_14078fc90(local_318);
      if (iVar2 == 0) {
        iVar2 = FUN_1403b3d30(&DAT_141154ae7);
        FUN_1407b4700(local_318,0,0x200);
        local_388 = FUN_14078fad0(iVar2);
        FUN_1407adae0(local_318,0x140f8e2a8,0x140f92718,iVar2);
        FUN_14078fc90(local_318);
        if (iVar2 == 0) {
          cVar1 = FUN_1403c49d0();
          FUN_1407b4700(local_318,0,0x100);
          FUN_1407adb40(local_318,0x140f8e2c0,0x140f927a0,cVar1);
          FUN_14078fc90(local_318);
          if (cVar1 == '\0') {
            FUN_14078fc90(0x140f927c0);
            uVar3 = 1;
          }
          else {
            local_378[0] = 0;
            cVar1 = FUN_1403b28f0(local_378);
            FUN_1407b4700(local_118,0,0x100);
            local_388 = FUN_14078fad0(local_378[0]);
            FUN_1407adb40(local_118,0x140f927e8,cVar1 != '\0');
            FUN_14078fc90(local_118);
            switch(local_378[0]) {
            case 0xffffffc3:
            case 0xffffffd7:
            case 0xffffffe4:
            case 0xffffffe5:
            case 0xffffffe9:
            case 0xffffffea:
            case 0xffffffeb:
              FUN_14078fc90(0x140f92820);
              uVar3 = FUN_1407a3000(local_378[0]);
              break;
            default:
              if (cVar1 == '\0') {
                switch(local_378[0]) {
                case 0xffffffd9:
                case 0xffffffda:
                case 0xfffffff0:
                case 0xfffffffc:
                case 0xfffffffd:
                case 0xfffffffe:
                case 0xffffffff:
                case 0:
                  break;
                default:
                  FUN_14078fc90(0x140f92850);
                  uVar3 = FUN_1407a3000(local_378[0]);
                  return uVar3;
                }
              }
              FUN_14078fc90(0x140f92880);
              uVar3 = 1;
            }
          }
        }
        else {
          switch(iVar2) {
          case -0x3d:
          case -0x29:
          case -0x1c:
          case -0x1b:
          case -0x17:
          case -0x16:
          case -0x15:
            break;
          default:
            switch(iVar2) {
            case -0x27:
            case -0x26:
            case -0x10:
            case -4:
            case -3:
            case -2:
            case -1:
            case 0:
              FUN_14078fc90(0x140f92770);
              return 1;
            }
          }
          FUN_14078fc90(0x140f92740);
          uVar3 = FUN_1407a3000(iVar2);
        }
      }
      else {
        FUN_14078fc90(0x140f926f0);
        uVar3 = 1;
      }
    }
    else {
      FUN_14078fc90(0x140f92660);
      uVar3 = 1;
    }
  }
  return uVar3;
}


// ==== FUN_1407a3080 @ 1407a3080 ====

/* WARNING: Function: __security_check_cookie replaced with injection: security_check_cookie */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 FUN_1407a3080(void)

{
  char cVar1;
  int iVar2;
  undefined8 uVar3;
  undefined1 auStack_3a8 [32];
  undefined8 local_388;
  undefined4 local_378 [4];
  undefined1 local_368 [80];
  undefined1 local_318 [512];
  undefined1 local_118 [256];
  ulonglong local_18;
  
  local_18 = _DAT_140f9e010 ^ (ulonglong)auStack_3a8;
  FUN_14078fc90(0x140f92508);
  if ((((_DAT_141154ced == 1) && (_DAT_141154cf1 == 1)) && (DAT_141154ae7 != '\0')) &&
     (_DAT_141154ce9 != 0)) {
    cVar1 = '\x01';
  }
  else {
    cVar1 = '\0';
  }
  FUN_1407b4700(local_318,0,0x100);
  FUN_1407adb40(local_318,0x140f8e2c0,0x140f92520,cVar1);
  FUN_14078fc90(local_318);
  if (cVar1 == '\0') {
    uVar3 = 0;
  }
  else {
    iVar2 = FUN_1403b34d0(0x140f92550,30000,0);
    FUN_1407b4700(local_318,0,0x200);
    local_388 = FUN_14078fad0(iVar2);
    FUN_1407adae0(local_318,0x140f8e2a8,0x140f92640,iVar2);
    FUN_14078fc90(local_318);
    if (iVar2 == 0) {
      FUN_1405a03d0();
      FUN_1403b3280(0x140f92688,0x405);
      FUN_14078fc90(0x140f92698);
      iVar2 = FUN_1403c47e0(local_368);
      FUN_1407b4700(local_318,0,0x200);
      local_388 = FUN_14078fad0(iVar2);
      FUN_1407adae0(local_318,0x140f8e2a8,0x140f926c8,iVar2);
      FUN_14078fc90(local_318);
      if (iVar2 == 0) {
        iVar2 = FUN_1403b3d30(&DAT_141154ae7);
        FUN_1407b4700(local_318,0,0x200);
        local_388 = FUN_14078fad0(iVar2);
        FUN_1407adae0(local_318,0x140f8e2a8,0x140f92718,iVar2);
        FUN_14078fc90(local_318);
        if (iVar2 == 0) {
          cVar1 = FUN_1403c49d0();
          FUN_1407b4700(local_318,0,0x100);
          FUN_1407adb40(local_318,0x140f8e2c0,0x140f927a0,cVar1);
          FUN_14078fc90(local_318);
          if (cVar1 == '\0') {
            FUN_14078fc90(0x140f927c0);
            uVar3 = 1;
          }
          else {
            local_378[0] = 0;
            cVar1 = FUN_1403b28f0(local_378);
            FUN_1407b4700(local_118,0,0x100);
            local_388 = FUN_14078fad0(local_378[0]);
            FUN_1407adb40(local_118,0x140f927e8,cVar1 != '\0');
            FUN_14078fc90(local_118);
            switch(local_378[0]) {
            case 0xffffffc3:
            case 0xffffffd7:
            case 0xffffffe4:
            case 0xffffffe5:
            case 0xffffffe9:
            case 0xffffffea:
            case 0xffffffeb:
              FUN_14078fc90(0x140f92820);
              uVar3 = FUN_1407a3000(local_378[0]);
              break;
            default:
              if (cVar1 == '\0') {
                switch(local_378[0]) {
                case 0xffffffd9:
                case 0xffffffda:
                case 0xfffffff0:
                case 0xfffffffc:
                case 0xfffffffd:
                case 0xfffffffe:
                case 0xffffffff:
                case 0:
                  break;
                default:
                  FUN_14078fc90(0x140f92850);
                  uVar3 = FUN_1407a3000(local_378[0]);
                  return uVar3;
                }
              }
              FUN_14078fc90(0x140f92880);
              uVar3 = 1;
            }
          }
        }
        else {
          switch(iVar2) {
          case -0x3d:
          case -0x29:
          case -0x1c:
          case -0x1b:
          case -0x17:
          case -0x16:
          case -0x15:
            break;
          default:
            switch(iVar2) {
            case -0x27:
            case -0x26:
            case -0x10:
            case -4:
            case -3:
            case -2:
            case -1:
            case 0:
              FUN_14078fc90(0x140f92770);
              return 1;
            }
          }
          FUN_14078fc90(0x140f92740);
          uVar3 = FUN_1407a3000(iVar2);
        }
      }
      else {
        FUN_14078fc90(0x140f926f0);
        uVar3 = 1;
      }
    }
    else {
      FUN_14078fc90(0x140f92660);
      uVar3 = 1;
    }
  }
  return uVar3;
}


// ==== FUN_1407a4b90 @ 1407a4b90 ====

/* WARNING: Control flow encountered bad instruction data */
/* WARNING: Instruction at (ram,0x0001407a52d4) overlaps instruction at (ram,0x0001407a52d0)
    */
/* WARNING: Function: __chkstk replaced with injection: alloca_probe */
/* WARNING: Function: __security_check_cookie replaced with injection: security_check_cookie */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

ulonglong FUN_1407a4b90(int param_1,longlong param_2)

{
  code *pcVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined8 ****ppppuVar4;
  undefined8 *puVar5;
  undefined8 *puVar6;
  byte bVar7;
  short sVar8;
  int iVar9;
  uint uVar10;
  int iVar11;
  char *pcVar12;
  undefined7 uVar18;
  undefined4 *puVar13;
  undefined2 *puVar14;
  ulonglong uVar15;
  char *pcVar16;
  longlong lVar17;
  undefined8 uVar19;
  undefined8 *puVar20;
  undefined8 ****ppppuVar21;
  char **_Source;
  undefined8 ****ppppuVar22;
  uint *puVar23;
  undefined8 *puVar24;
  longlong unaff_RBX;
  longlong lVar25;
  undefined8 **ppuVar26;
  undefined8 **ppuVar27;
  undefined1 *puVar28;
  undefined1 *puVar29;
  undefined1 *puVar30;
  undefined4 *puVar31;
  undefined1 *puVar32;
  undefined1 *puVar33;
  undefined1 *puVar34;
  undefined4 *puVar35;
  int iVar36;
  undefined8 uVar37;
  undefined8 *****pppppuVar38;
  ulonglong uVar39;
  ulonglong uVar40;
  undefined8 *****pppppuVar41;
  int iVar42;
  bool bVar43;
  byte in_AF;
  bool bVar44;
  undefined1 uVar45;
  char cVar46;
  char cVar47;
  bool bVar48;
  byte in_TF;
  byte in_IF;
  char cVar49;
  char cVar50;
  bool bVar51;
  byte in_NT;
  byte in_AC;
  byte in_VIF;
  byte in_VIP;
  byte in_ID;
  undefined4 uVar52;
  longlong alStack_a130 [13];
  undefined8 *local_a0c8;
  longlong lStack_a0c0;
  longlong local_a0b8;
  byte abStack_a0b0 [16];
  int local_a0a0;
  byte local_a09c [4];
  int local_a098 [3];
  char local_a08a [34];
  int local_a068;
  undefined1 local_a062 [18];
  int local_a050 [6];
  uint local_a038 [3];
  undefined4 uStack_a02c;
  uint local_a028 [8];
  undefined8 uStack_a008;
  undefined8 local_9ff8;
  undefined8 auStack_9fc8 [2];
  undefined8 local_9fb8 [3];
  char local_9f9b;
  uint local_9f98 [6];
  uint local_9f80;
  undefined4 local_9f74;
  int local_9f70 [8];
  undefined8 local_9f50;
  char *local_9f48;
  char *local_9f40;
  undefined4 local_9f38;
  undefined4 local_9f34;
  undefined4 uStack_9f30;
  undefined4 uStack_9f2c;
  undefined4 uStack_9f28;
  undefined4 uStack_9f24;
  undefined8 uStack_9f20;
  undefined4 uStack_9f18;
  undefined4 local_9f14;
  undefined4 uStack_9f10;
  undefined8 uStack_9f0c;
  undefined8 local_9f04;
  undefined8 uStack_9efc;
  undefined8 local_9ef4;
  undefined8 uStack_9eec;
  undefined8 local_9ee4;
  undefined8 uStack_9edc;
  undefined8 local_9ed4;
  undefined4 local_9ecc;
  undefined1 local_9ec0 [312];
  undefined8 auStack_9d88 [112];
  undefined2 local_9a08;
  undefined2 uStack_9a06;
  undefined4 uStack_9a04;
  undefined4 uStack_9a00;
  undefined4 uStack_99fc;
  longlong local_99f8;
  ulonglong uStack_99f0;
  undefined8 ****local_99c8 [2];
  longlong local_99b8;
  ulonglong uStack_99b0;
  uint local_9868;
  undefined4 uStack_9864;
  undefined4 uStack_9860;
  undefined4 uStack_985c;
  undefined8 ***local_9858;
  undefined8 ***pppuStack_9850;
  undefined2 local_97c8;
  undefined6 uStack_97c6;
  undefined8 local_97b8;
  ulonglong local_97b0;
  undefined1 auStack_9708 [32];
  undefined1 auStack_96e8 [160];
  undefined1 local_9648 [1312];
  undefined1 auStack_9128 [32];
  undefined1 auStack_9108 [32];
  undefined1 auStack_90e8 [160];
  undefined1 local_9048 [3797];
  char local_8173 [75];
  char local_8128 [254];
  undefined1 local_802a;
  char local_8028 [254];
  undefined1 local_7f2a;
  undefined1 local_7e28 [512];
  undefined1 local_7c28 [1024];
  undefined1 local_7828 [3968];
  undefined8 auStack_68a8 [111];
  undefined1 auStack_652e [1782];
  undefined1 local_5e38 [16032];
  undefined1 local_1f98 [8016];
  ulonglong local_48;
  undefined8 uStack_40;
  
  uStack_40 = 0x1407a4bb2;
  local_48 = _DAT_140f9e010 ^ (ulonglong)&local_a0b8;
  uVar40 = (ulonglong)param_1;
  iVar42 = 0;
  iVar11 = 0;
  iVar36 = 1;
  local_a050[2] = param_1;
  if ((longlong)uVar40 < 2) {
LAB_1407a4c98:
    bVar51 = false;
    if (1 < (longlong)uVar40) goto LAB_1407a4ca1;
  }
  else {
    unaff_RBX = 1;
    do {
      lStack_a0c0 = 0x1407a4c00;
      iVar9 = FUN_1407be830(*(undefined8 *)(param_2 + unaff_RBX * 8),0x140f8dc90);
      if (iVar9 != 0) {
        lStack_a0c0 = 0x1407a4c14;
        iVar9 = FUN_1407be830(*(undefined8 *)(param_2 + unaff_RBX * 8),0x140f8dca0);
        if (iVar9 != 0) {
          lStack_a0c0 = 0x1407a4c28;
          iVar9 = FUN_1407be830(*(undefined8 *)(param_2 + unaff_RBX * 8),0x140f92328);
          if (iVar9 != 0) {
            lStack_a0c0 = 0x1407a4c3c;
            iVar9 = FUN_1407be830(*(undefined8 *)(param_2 + unaff_RBX * 8),0x140f92330);
            if (iVar9 != 0) {
              iVar36 = iVar36 + 1;
              if (iVar36 < param_1) {
                lStack_a0c0 = 0x1407a4c60;
                iVar9 = FUN_1407be830(*(undefined8 *)(param_2 + unaff_RBX * 8),0x140f92334);
                if (iVar9 == 0) {
                  lStack_a0c0 = 0x1407a4c75;
                  iVar9 = FUN_1407be830(*(undefined8 *)(param_2 + 8 + unaff_RBX * 8),0x140f92338);
                  if (iVar9 == 0) {
                    iVar11 = iVar11 + 1;
                    unaff_RBX = unaff_RBX + 1;
                    goto LAB_1407a4c7f;
                  }
                }
              }
              bVar51 = false;
              goto LAB_1407a4ca1;
            }
            iVar42 = iVar42 + 1;
          }
        }
      }
LAB_1407a4c7f:
      iVar36 = iVar36 + 1;
      unaff_RBX = unaff_RBX + 1;
    } while (unaff_RBX < (longlong)uVar40);
    if (iVar42 == 1) {
      if (iVar11 != 0) goto LAB_1407a4c98;
    }
    else if ((iVar42 != 0) || (iVar11 != 1)) goto LAB_1407a4c98;
    bVar51 = true;
LAB_1407a4ca1:
    unaff_RBX = 1;
    do {
      lStack_a0c0 = 0x1407a4cc0;
      iVar36 = FUN_1407be830(*(undefined8 *)(param_2 + unaff_RBX * 8),0x140f9233c);
      if (iVar36 == 0) {
        local_a062[0xd] = 1;
        goto LAB_1407a4cfa;
      }
      unaff_RBX = unaff_RBX + 1;
    } while (unaff_RBX < (longlong)uVar40);
  }
  local_a062[0xd] = 0;
  if (1 < (longlong)uVar40) {
LAB_1407a4cfa:
    unaff_RBX = 1;
    do {
      lStack_a0c0 = 0x1407a4d10;
      iVar36 = FUN_1407be830(*(undefined8 *)(param_2 + unaff_RBX * 8),0x140f92328);
      if (iVar36 == 0) {
        bVar43 = true;
        goto LAB_1407a4d29;
      }
      unaff_RBX = unaff_RBX + 1;
    } while (unaff_RBX < (longlong)uVar40);
  }
  bVar43 = false;
  if (1 < (longlong)uVar40) {
LAB_1407a4d29:
    unaff_RBX = 1;
    do {
      lStack_a0c0 = 0x1407a4d40;
      iVar36 = FUN_1407be830(*(undefined8 *)(param_2 + unaff_RBX * 8),0x140f8dc90);
      if (iVar36 != 0) {
        lStack_a0c0 = 0x1407a4d54;
        iVar36 = FUN_1407be830(*(undefined8 *)(param_2 + unaff_RBX * 8),0x140f8dca0);
        if (iVar36 != 0) {
          bVar48 = true;
          goto LAB_1407a4d6d;
        }
      }
      unaff_RBX = unaff_RBX + 1;
    } while (unaff_RBX < (longlong)uVar40);
  }
  bVar48 = false;
  cVar49 = SBORROW8(uVar40,1);
  lVar25 = uVar40 - 1;
  if (1 < (longlong)uVar40) {
LAB_1407a4d6d:
    unaff_RBX = 1;
    do {
      uVar19 = *(undefined8 *)(param_2 + unaff_RBX * 8);
      lStack_a0c0 = 0x1407a4d80;
      iVar36 = FUN_1407be830(uVar19,0x140f8dc90);
      ppuVar26 = (undefined8 **)&local_a0b8;
      if (iVar36 == 0) goto LAB_1407a4dc7;
      unaff_RBX = unaff_RBX + 1;
      cVar49 = SBORROW8(unaff_RBX,uVar40);
      lVar25 = unaff_RBX - uVar40;
    } while (unaff_RBX < (longlong)uVar40);
  }
  cVar46 = lVar25 < 0;
  uVar37 = 1;
  uVar19 = 0x10;
  ppuVar27 = (undefined8 **)&lStack_a0c0;
  local_a0c8 = (undefined8 *)0x1407a4d97;
  lStack_a0c0 = unaff_RBX;
  sVar8 = FUN_1407756fd();
  ppuVar26 = (undefined8 **)&lStack_a0c0;
  if (sVar8 < 0) goto LAB_1407a4dc7;
  uVar19 = 0xa0;
  local_a0c8 = (undefined8 *)0x1407a4da8;
  uVar10 = func_0x000141a630de();
  if (cVar49 != cVar46) {
    ppuVar26 = (undefined8 **)&lStack_a0c0;
    if ((uVar10 >> 0xf & 1) == 0) {
      uVar19 = 0xa1;
      ppuVar26 = &local_a0c8;
      local_a0c8 = local_9fb8;
      sVar8 = func_0x00014189fb7f();
      local_a062[0] = 0;
      ppuVar27 = &local_a0c8;
      if (sVar8 < 0) goto LAB_1407a4dc7;
    }
    else {
LAB_1407a4dc7:
      *(undefined1 *)((longlong)ppuVar26 + 0x66) = 1;
      ppuVar27 = ppuVar26;
    }
    if (1 < (longlong)uVar40) {
      lVar25 = 1;
      do {
        uVar19 = *(undefined8 *)(param_2 + lVar25 * 8);
        *(undefined8 *)((longlong)ppuVar27 + -8) = 0x1407a4df0;
        iVar36 = FUN_1407be830(uVar19,0x140f8dca0);
        if (iVar36 == 0) {
          uVar37 = 1;
          goto LAB_1407a4e03;
        }
        lVar25 = lVar25 + 1;
      } while (lVar25 < (longlong)uVar40);
    }
    uVar37 = 0;
  }
LAB_1407a4e03:
  cVar49 = (char)uVar37;
  *(undefined4 *)((longlong)ppuVar27 + 0x78) = 0;
  local_9f50 = 0;
  *(undefined8 *)((longlong)ppuVar27 + -8) = uVar19;
  *(undefined8 *)((longlong)ppuVar27 + -0x10) = 0x1407a4e1c;
  DAT_14115c479 = cVar49;
  uVar19 = func_0x0001418f544d();
  puVar29 = (undefined1 *)((longlong)ppuVar27 + -0x10);
  *(undefined8 *)((longlong)ppuVar27 + -0x10) = uVar19;
  *(undefined8 *)((longlong)ppuVar27 + -0x18) = 0x1407a4e2e;
  iVar36 = func_0x0001416a74a6(uVar19,8,&local_9f50);
  if (iVar36 == 0) {
LAB_1407a4ef2:
    *(undefined8 *)(puVar29 + -8) = 0x1407a4efe;
    FUN_140789f80(0x140f929e0);
    *(undefined8 *)(puVar29 + -8) = 0x1407a4f0a;
    FUN_140789f80(0x140f929f8);
    iVar11 = 0x104;
    puVar28 = puVar29 + -8;
    puVar35 = (undefined4 *)(puVar29 + -8);
    *(longlong *)(puVar29 + -8) = param_2;
    *(undefined8 *)(puVar29 + -0x10) = 0x1407a4f1f;
    iVar36 = func_0x00014118d59e(0,local_7828);
    puVar32 = puVar29 + -8;
    if (iVar36 == 0) goto LAB_1407a4e82;
    *(undefined8 *)(puVar29 + -0x10) = 0x1407a4f33;
    FUN_140799d20(&local_9a08);
    if (puVar29[0x5e] != '\0') {
      *(undefined8 *)(puVar29 + -0x10) = 0x1407a4f52;
      uVar19 = FUN_1407abfb0(local_9ec0,&local_9a08);
      *(undefined8 *)(puVar29 + -0x10) = 0x1407a4f61;
      puVar13 = (undefined4 *)FUN_140799e30(&local_97c8,uVar19);
      if ((undefined4 *)&local_9a08 != puVar13) {
        if (7 < uStack_99f0) {
          uVar15 = uStack_99f0 * 2 + 2;
          lVar17 = CONCAT44(uStack_9a04,CONCAT22(uStack_9a06,local_9a08));
          lVar25 = lVar17;
          if (0xfff < uVar15) {
            uVar15 = uStack_99f0 * 2 + 0x29;
            lVar25 = *(longlong *)(lVar17 + -8);
            if (0x1f < (lVar17 - lVar25) - 8U) goto LAB_1407aa70a;
          }
          *(undefined8 *)(puVar29 + -0x10) = 0x1407a4fba;
          thunk_FUN_1407c68b0(lVar25,uVar15);
        }
        uStack_9a04 = puVar13[1];
        uStack_9a00 = puVar13[2];
        uStack_99fc = puVar13[3];
        local_9a08 = (undefined2)*puVar13;
        uStack_9a06 = (undefined2)((uint)*puVar13 >> 0x10);
        local_99f8 = *(longlong *)(puVar13 + 4);
        uStack_99f0 = *(ulonglong *)(puVar13 + 6);
        *(undefined8 *)(puVar13 + 4) = 0;
        *(undefined8 *)(puVar13 + 6) = 7;
        *(undefined2 *)puVar13 = 0;
      }
      if (7 < local_97b0) {
        if (0xfff < local_97b0 * 2 + 2) {
          uVar15 = local_97b0 * 2 + 0x29;
          lVar25 = *(longlong *)(CONCAT62(uStack_97c6,local_97c8) + -8);
          if (0x1f < (CONCAT62(uStack_97c6,local_97c8) - lVar25) - 8U) {
LAB_1407aa70a:
                    /* WARNING: Subroutine does not return */
            *(undefined **)(puVar29 + -0x10) = &UNK_1407aa70f;
            FUN_1407b8bd4(lVar25,uVar15);
          }
        }
        *(undefined8 *)(puVar29 + -0x10) = 0x1407a5046;
        thunk_FUN_1407c68b0();
      }
      local_97b8 = 0;
      local_97b0 = 7;
      local_97c8 = 0;
    }
    puVar14 = (undefined2 *)0x0;
    local_9f38 = 0x70;
    local_9f34 = 0;
    uStack_9f10 = 0;
    local_9f04 = 0;
    uStack_9efc = 0;
    local_9ef4 = 0;
    uStack_9eec = 0;
    local_9ee4 = 0;
    uStack_9edc = 0;
    local_9ed4 = 0;
    local_9ecc = 0;
    uStack_9f28 = 0x40f92a20;
    uStack_9f24 = 1;
    uStack_9f20 = local_7828;
    if (local_99f8 != 0) {
      puVar14 = &local_9a08;
      if (7 < uStack_99f0) {
        puVar14 = (undefined2 *)CONCAT44(uStack_9a04,CONCAT22(uStack_9a06,local_9a08));
      }
    }
    uStack_9f18 = SUB84(puVar14,0);
    local_9f14 = (undefined4)((ulonglong)puVar14 >> 0x20);
    uStack_9f30 = 0;
    uStack_9f2c = 0;
    uStack_9f0c = 0x100000000;
    *(undefined8 *)(puVar29 + -0x10) = 0x1407a5111;
    func_0x0001417e8953(&local_9f38);
    if (iVar11 != 0) {
      *(undefined8 *)(puVar29 + -0x10) = 0x1407a5122;
      FUN_140789f80(0x140f92a30);
      *(undefined8 *)(puVar29 + -0x10) = 0x1407a512e;
      uVar19 = FUN_140789f80(0x140f92a50);
      *(undefined8 *)(puVar29 + -0x10) = uVar19;
      *(undefined8 *)(puVar29 + -0x18) = 0x1407a5136;
      func_0x0001415a7b97(0);
      pcVar1 = (code *)swi(3);
      uVar40 = (*pcVar1)();
      return uVar40;
    }
    *(undefined8 *)(puVar29 + -0x10) = 0x1407a5143;
    FUN_140789f80(0x140f92a78);
    *(undefined8 *)(puVar29 + -0x10) = 0x1407a514f;
    FUN_140789f80(0x140f92a90);
    if (7 < uStack_99f0) {
      ppppuVar22 = (undefined8 ****)(uStack_99f0 * 2 + 2);
      ppppuVar4 = (undefined8 ****)CONCAT44(uStack_9a04,CONCAT22(uStack_9a06,local_9a08));
      ppppuVar21 = ppppuVar4;
      if ((undefined8 ****)0xfff < ppppuVar22) {
        ppppuVar22 = (undefined8 ****)(uStack_99f0 * 2 + 0x29);
        ppppuVar21 = (undefined8 ****)ppppuVar4[-1];
        if (0x1f < (ulonglong)((longlong)ppppuVar4 + (-8 - (longlong)ppppuVar21))) {
LAB_1407aa704:
                    /* WARNING: Subroutine does not return */
          *(undefined **)((longlong)puVar35 + -8) = &UNK_1407aa709;
          FUN_1407b8bd4(ppppuVar21,ppppuVar22);
        }
      }
      *(undefined8 *)(puVar29 + -0x10) = 0x1407a5196;
      thunk_FUN_1407c68b0(ppppuVar21,ppppuVar22);
    }
    local_99f8 = 0;
    uStack_99f0 = 7;
    local_9a08 = 0;
  }
  else {
    local_9f74 = 4;
    *(undefined4 **)((longlong)ppuVar27 + 0x10) = &local_9f74;
    *(undefined8 *)((longlong)ppuVar27 + -0x18) = uVar37;
    *(undefined8 *)((longlong)ppuVar27 + -0x20) = 0x1407a4e5e;
    iVar11 = func_0x00014199480d(local_9f50,0x14,local_9f70);
    iVar36 = 0;
    if (iVar11 != 0) {
      iVar36 = local_9f70[0];
    }
    *(int *)((longlong)ppuVar27 + 0x60) = iVar36;
    puVar29 = (undefined1 *)((longlong)ppuVar27 + -0x20);
    *(undefined8 *)((longlong)ppuVar27 + -0x20) = local_9f50;
    *(undefined8 *)((longlong)ppuVar27 + -0x28) = 0x1407a4e72;
    func_0x0001419b7c4d();
    if (iVar36 == 0) goto LAB_1407a4ef2;
    *(undefined8 *)((longlong)ppuVar27 + -0x28) = 0x1407a4e82;
    FUN_140789f80(0x140f929c8);
    puVar32 = (undefined1 *)((longlong)ppuVar27 + -0x20);
LAB_1407a4e82:
    puVar28 = puVar32;
  }
  uVar15 = (ulonglong)_DAT_141154d10;
  puVar32 = puVar28;
  if ((int)_DAT_141154d10 < 0) {
    puVar32 = puVar28 + -8;
    *(undefined8 *)(puVar28 + -8) = uVar37;
    *(undefined8 *)(puVar28 + -0x10) = 0x1407a4e9f;
    uVar10 = func_0x0001413da609(0x140f8d130);
    if ((uVar10 == 0xffffffff) || ((uVar10 & 0x10) == 0)) {
      cVar47 = -0x2f;
      *(undefined8 *)(puVar28 + -0x10) = 0x1407a4eb8;
      pcVar12 = (char *)FUN_14077da18();
      cRamffffffff840ffff8 = cRamffffffff840ffff8 - (char)pcVar12;
      uVar18 = (undefined7)((ulonglong)pcVar12 >> 8);
      cVar46 = (char)pcVar12 + *pcVar12;
      pcVar16 = (char *)CONCAT71(uVar18,cVar46);
      pcVar12 = pcVar16 + -0x157bf0f0;
      *pcVar12 = *pcVar12 + cVar47;
      uVar15 = CONCAT71(uVar18,cVar46 + *pcVar16);
      *(undefined1 *)(uVar15 + 1) = *(undefined1 *)(uVar15 + 1);
      _DAT_141154d10 = (uint)uVar15;
      puVar32 = puVar28 + -8;
    }
    else {
      _DAT_141154d10 = 0;
      uVar15 = 0;
    }
  }
  cVar46 = -0x1d;
  uVar19 = 0x140f8e3d8;
  if ((int)uVar15 == 1) {
    uVar19 = 0x140f8e3b8;
  }
  *(undefined8 *)(puVar32 + -8) = 0x1407a51d6;
  uRamffffffff940ffff8 = func_0x000141b1b013(uVar19);
  LOCK();
  UNLOCK();
  puVar30 = puVar32;
  if ((int)_DAT_141154d10 < 0) {
    puVar30 = puVar32 + -8;
    *(undefined8 **)(puVar32 + -8) = local_9fb8;
    *(undefined8 *)(puVar32 + -0x10) = 0x1407a51f6;
    uVar10 = func_0x00014156296e(0x140f8d130);
    if ((uVar10 == 0xffffffff) || ((uVar10 & 0x10) == 0)) {
      *(undefined8 *)(puVar32 + -0x10) = 0x1407a520b;
      bVar7 = func_0x000141a339b3(0x140f8d148);
      cRam000000001174fff8 = cRam000000001174fff8 - bVar7;
      if ((bVar7 & 0x10) != 0) {
        _DAT_141154d10 = 1;
        puVar30 = puVar32 + -8;
        goto LAB_1407a522a;
      }
    }
    _DAT_141154d10 = 0;
  }
LAB_1407a522a:
  uVar19 = 0x140f8e420;
  if (_DAT_141154d10 == 1) {
    uVar19 = 0x140f8e3f8;
  }
  cVar50 = '\0';
  cVar47 = (int)_DAT_141154d10 < 0;
  bVar44 = _DAT_141154d10 == 0;
  puVar13 = (undefined4 *)puVar30;
  if ((bool)cVar47) {
    *(undefined8 *)(puVar30 + -8) = 0x1407a524f;
    lVar25 = func_0x00014147abe6(0x140f8d130);
    if (bVar44 || cVar50 != cVar47) {
                    /* WARNING: Bad instruction - Truncating control flow here */
      halt_baddata();
    }
    *(undefined8 *)(puVar30 + -8) = *(undefined8 *)(puVar30 + lVar25 + -0x58);
    local_9f9b = local_9f9b + cVar46;
    puVar13 = (undefined4 *)(puVar30 + -0x10);
    *(longlong *)(puVar30 + -0x10) = param_2;
    *(undefined8 *)(puVar30 + -0x18) = 0x1407a5266;
    uVar10 = func_0x00014118d67d(0x140f8d148);
    if ((uVar10 == 0xffffffff) || ((uVar10 & 0x10) == 0)) {
      _DAT_141154d10 = 0;
    }
    else {
      _DAT_141154d10 = 1;
      puVar13 = (undefined4 *)(puVar30 + -0x10);
    }
  }
  pcVar12 = (char *)(ulonglong)*(byte *)((longlong)puVar13 + 0x76);
  *(undefined8 *)((longlong)puVar13 + 0x20) = uVar19;
  *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a52b8;
  iVar36 = FUN_14078cd60(0x140f92ae0,*(int *)((longlong)puVar13 + 0x78) != 0,pcVar12);
  if (iVar36 != 0) {
    if (((char)pcVar12 == '\0') || (bVar48)) {
      if ((!bVar51) && (cVar49 == '\0')) {
        *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a530b;
        FUN_1407a1340();
        *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a5310;
        FUN_1407a1880();
      }
    }
    else if (!bVar51) {
      cVar47 = false;
      cVar46 = false;
      if (cVar49 == '\0') {
        while( true ) {
          DAT_14115c478 = 1;
          pcVar12 = (char *)0x140f90ec0;
          *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a52ea;
          cVar49 = func_0x000141af7b76(0x140f90ec0,0x140f90ebc);
          if (cVar47 == cVar46) break;
          cVar47 = SCARRY1(*pcVar12,cVar49);
          *pcVar12 = *pcVar12 + cVar49;
          cVar46 = *pcVar12 < '\0';
        }
                    /* WARNING: Bad instruction - Truncating control flow here */
        halt_baddata();
      }
    }
  }
  local_a038[0] = 0;
  iVar36 = *(int *)((longlong)puVar13 + 0x70);
  *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a532b;
  cVar49 = FUN_1407a1fa0(iVar36,param_2,local_a038);
  if (cVar49 == '\0') {
    if (!bVar51) {
      *(undefined1 *)((longlong)puVar13 + 0x77) = 0;
      puVar32 = (undefined1 *)0x0;
      *(undefined1 *)((longlong)puVar13 + 0x65) = 0;
      *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a5398;
      FUN_1407b4700(local_8028,0,0xff);
      *(undefined1 *)((longlong)puVar13 + 0x60) = 0;
      *(undefined4 *)((longlong)puVar13 + 0x70) = 0;
      *(undefined1 *)((longlong)puVar13 + 0x61) = 0;
      local_a038[0] = 0;
      *(undefined1 *)((longlong)puVar13 + 0x62) = 0;
      *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a53c7;
      FUN_1407b4700(local_8128,0,0xff);
      *(undefined1 *)((longlong)puVar13 + 0x67) = 0;
      *(undefined1 *)((longlong)puVar13 + 100) = 0;
      *(undefined1 *)((longlong)puVar13 + 0x74) = 0;
      *(undefined1 *)((longlong)puVar13 + 0x75) = 0;
      _Source = (char **)0x0;
      *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a53ef;
      FUN_1407b4700(local_7e28,0,0xff);
      uVar15 = 1;
      if (1 < (longlong)uVar40) {
        lVar25 = 1;
        do {
          iVar42 = (int)uVar15;
          _Source = (char **)0x140f8dc90;
          *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a5420;
          iVar11 = FUN_1407be830();
          if (iVar11 != 0) {
            _Source = (char **)0x140f8dca0;
            *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a5438;
            iVar11 = FUN_1407be830();
            if (iVar11 != 0) {
              _Source = (char **)0x140f9233c;
              *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a5450;
              iVar11 = FUN_1407be830();
              if (iVar11 == 0) {
                *(undefined1 *)((longlong)puVar13 + 99) = 1;
              }
              else {
                uVar19 = *(undefined8 *)(param_2 + lVar25 * 8);
                *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a546e;
                iVar11 = FUN_1407be830(uVar19,0x140f92b1c);
                if (iVar11 == 0) {
                  if ((((iVar42 + 1 < iVar36) &&
                       (_Source = *(char ***)(param_2 + 8 + lVar25 * 8), _Source != (char **)0x0))
                      && (*(byte *)_Source != 0)) &&
                     ((*(byte *)_Source != 0x2d || (*(byte *)((longlong)_Source + 1) == 0)))) {
                    *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a54b6;
                    strncpy(local_8128,(char *)_Source,0xfe);
                    local_802a = 0;
                    *(undefined1 *)((longlong)puVar13 + 0x62) = 1;
                    goto LAB_1407a563d;
                  }
                  goto LAB_1407a56a7;
                }
                _Source = (char **)0x140f92b50;
                *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a54d7;
                iVar11 = FUN_1407be830();
                if (iVar11 == 0) {
                  *(undefined1 *)((longlong)puVar13 + 0x67) = 1;
                }
                else {
                  _Source = (char **)0x140f92328;
                  *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a54f5;
                  iVar11 = FUN_1407be830();
                  if (iVar11 != 0) {
                    uVar19 = *(undefined8 *)(param_2 + lVar25 * 8);
                    *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a5513;
                    uVar15 = FUN_1407be830(uVar19,0x140f92b58);
                    if ((int)uVar15 == 0) {
                      if ((iVar42 + 1 < iVar36) &&
                         (_Source = *(char ***)(param_2 + 8 + lVar25 * 8), _Source != (char **)0x0))
                      {
                        bVar7 = *(byte *)_Source;
                        uVar15 = (ulonglong)bVar7;
                        if ((bVar7 != 0) &&
                           ((bVar7 != 0x2d || (*(byte *)((longlong)_Source + 1) == 0)))) {
                          *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a555b;
                          strncpy(local_8028,(char *)_Source,0xfe);
                          local_7f2a = 0;
                          *(undefined1 *)((longlong)puVar13 + 0x65) = 1;
                          goto LAB_1407a563d;
                        }
                      }
                      *(ulonglong *)((longlong)puVar13 + -8) = uVar15;
                      *(undefined8 *)((longlong)puVar13 + -0x10) = 0x1407a56e8;
                      func_0x000141997c81(0,0x140f92b60,0x140f92b20,0x10);
                      *(undefined8 *)((longlong)puVar13 + -0x10) = 0x1407a56ef;
                      func_0x0001419e7085(0);
                      puVar32 = (undefined1 *)((longlong)puVar13 + -8);
                    }
                    else {
                      uVar19 = *(undefined8 *)(param_2 + lVar25 * 8);
                      *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a557c;
                      iVar11 = FUN_1407be830(uVar19,0x140f92b7c);
                      if (iVar11 != 0) {
                        uVar19 = *(undefined8 *)(param_2 + lVar25 * 8);
                        *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a55e4;
                        iVar11 = FUN_1407be830(uVar19,0x140f92ba0);
                        if (iVar11 != 0) {
                          *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a574f;
                          FUN_1407b4700(local_7c28,0,0x200);
                          uVar19 = *(undefined8 *)(param_2 + (longlong)iVar42 * 8);
                          *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a5769;
                          uVar19 = FUN_1407adae0(local_7c28,0x140f92bd0,uVar19);
                          *(undefined8 *)((longlong)puVar13 + -8) = uVar19;
                          *(undefined8 *)((longlong)puVar13 + -0x10) = 0x1407a5785;
                          func_0x000141912b82(0,local_7c28,0x140f92b20,0x10);
                          *(undefined8 *)((longlong)puVar13 + -0x10) = 0x1407a578c;
                          func_0x0001416d96bd(0);
                          pcVar1 = (code *)swi(3);
                          uVar40 = (*pcVar1)();
                          return uVar40;
                        }
                        if (((iVar36 <= iVar42 + 1) ||
                            (pcVar16 = *(char **)(param_2 + 8 + lVar25 * 8), pcVar16 == (char *)0x0)
                            ) || (*pcVar16 == '\0')) goto LAB_1407a5716;
                        local_9f40 = (char *)0x0;
                        _Source = &local_9f40;
                        *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a561f;
                        local_a038[0] = FUN_1407c0494(pcVar16,_Source,10);
                        if ((local_9f40 == (char *)0x0) || (*local_9f40 != '\0'))
                        goto LAB_1407a5716;
                        *(undefined1 *)((longlong)puVar13 + 0x61) = 1;
LAB_1407a563d:
                        iVar42 = iVar42 + 1;
                        lVar25 = lVar25 + 1;
                        goto LAB_1407a5640;
                      }
                      puVar32 = (undefined1 *)puVar13;
                      if (((iVar42 + 1 < iVar36) &&
                          (pcVar16 = *(char **)(param_2 + 8 + lVar25 * 8), pcVar16 != (char *)0x0))
                         && (*pcVar16 != '\0')) {
                        local_9f48 = (char *)0x0;
                        _Source = &local_9f48;
                        *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a55b3;
                        uVar52 = FUN_1407c0494(pcVar16,_Source,10);
                        *(undefined4 *)((longlong)puVar13 + 0x70) = uVar52;
                        if ((local_9f48 != (char *)0x0) && (*local_9f48 == '\0')) {
                          *(undefined1 *)((longlong)puVar13 + 0x60) = 1;
                          goto LAB_1407a563d;
                        }
                      }
                    }
                    puVar13 = (undefined4 *)(puVar32 + -8);
                    *(longlong *)(puVar32 + -8) = param_2;
                    *(undefined8 *)(puVar32 + -0x10) = 0x1407a570d;
                    func_0x0001416b36da(0,0x140f92b80,0x140f92b20,0x10);
                    *(undefined8 *)(puVar32 + -0x10) = 0x1407a5714;
                    func_0x000141a7ef6f(0);
LAB_1407a5716:
                    uVar19 = 0x140f92ba8;
                    *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a5731;
                    func_0x000141179a9c(0,0x140f92ba8,0x140f92b20,0x10);
                    *(undefined8 *)((longlong)puVar13 + -8) = uVar19;
                    *(undefined8 *)((longlong)puVar13 + -0x10) = 0x1407a573a;
                    func_0x0001417ebf7e(0);
                    pcVar1 = (code *)swi(3);
                    uVar40 = (*pcVar1)();
                    return uVar40;
                  }
                  *(undefined1 *)((longlong)puVar13 + 100) = 1;
                }
              }
            }
          }
LAB_1407a5640:
          uVar15 = (ulonglong)(iVar42 + 1);
          lVar25 = lVar25 + 1;
        } while (lVar25 < (longlong)uVar40);
        puVar32 = (undefined1 *)(ulonglong)*(byte *)((longlong)puVar13 + 0x65);
      }
      uVar39 = 1;
      pppppuVar38 = (undefined8 *****)&DAT_141154980;
      lVar25 = 6;
      uVar45 = *(char *)((longlong)puVar13 + 0x67) == '\0';
      puVar35 = puVar13;
      do {
        puVar13 = puVar35;
        cVar49 = (char)puVar32;
        if ((bool)uVar45) {
          if (*(char *)(puVar13 + 0x19) == '\0') {
            cVar46 = *(char *)(puVar13 + 0x18);
            _Source = (char **)(ulonglong)*(byte *)((longlong)puVar13 + 0x62);
            cVar47 = *(char *)((longlong)puVar13 + 0x61);
            goto LAB_1407a581a;
          }
          if (cVar49 != '\0') goto LAB_1407a581f;
          if (((*(char *)((longlong)puVar13 + 0x62) != '\0') || (*(char *)(puVar13 + 0x18) != '\0'))
             || (*(char *)((longlong)puVar13 + 0x61) != '\0')) goto LAB_1407a5899;
          if (*(char *)((longlong)puVar13 + 99) == '\0') {
            *(undefined8 *)(puVar13 + -2) = 0x1407a72d7;
            FUN_14079a100();
            *(ulonglong *)(puVar13 + -2) = uVar15;
            *(undefined8 *)(puVar13 + -4) = 0x1407a72df;
            func_0x000141600693(0);
            pcVar1 = (code *)swi(3);
            uVar40 = (*pcVar1)();
            return uVar40;
          }
LAB_1407a742d:
          *(undefined8 *)(puVar13 + -2) = 0x1407a7432;
          uVar19 = FUN_140790010();
          *(undefined8 *)(puVar13 + -2) = 0x1407a743a;
          uVar10 = func_0x000141610fb5(uVar19);
          uVar10 = uVar10 | _DAT_141154980;
          *(char *)(ulonglong)uVar10 = *(char *)(ulonglong)uVar10 + (char)uVar10;
          *(undefined8 *)(puVar13 + -2) = 0x1407a7449;
          uVar19 = FUN_140790010();
          *(undefined8 *)(puVar13 + 0xc) = 0;
          puVar13[10] = 0x80;
          puVar13[8] = 3;
          *(undefined8 *)(puVar13 + -2) = uVar19;
          *(undefined8 *)(puVar13 + -4) = 0x1407a7477;
          lVar25 = func_0x000141a99b13(uVar19,0x80000000,7,0);
          if (lVar25 != -1) {
            *(undefined8 *)(puVar13 + -4) = 0x1407a74f6;
            func_0x000141a463dd(lVar25,0);
            puVar23 = (uint *)(lVar25 + -0x10);
            *puVar23 = *puVar23 >> 1 | (uint)((*puVar23 & 1) != 0) << 0x1f;
            if ((int)uVar40 == -1) {
              uVar19 = 0x140f903a0;
              puVar35 = puVar13 + -2;
            }
            else {
              local_a028[0] = 0;
              *(undefined8 *)(puVar13 + 6) = 0;
              puVar35 = puVar13 + -4;
              *(uint **)(puVar13 + -4) = local_a028;
              *(undefined8 *)(puVar13 + -6) = 0x1407a752c;
              iVar36 = func_0x0001418938cd(lVar25,local_a028,4,local_9f98);
              uVar10 = local_a028[0];
              if ((iVar36 == 0) || (local_9f98[0] != 4)) {
                uVar19 = 0x140f903b8;
              }
              else if (uVar40 == (longlong)(int)local_a028[0] + 4U) {
                *(undefined8 *)(puVar13 + -6) = 0x1407a756b;
                uVar19 = FUN_1407b4700(local_1f98,0,0xa6e);
                puVar35 = puVar13 + -4;
                if (uVar10 < 0xa6f) {
                  *(undefined8 *)(puVar13 + 4) = 0;
                  *(undefined8 *)(puVar13 + -6) = uVar19;
                  *(undefined8 *)(puVar13 + -8) = 0x1407a7593;
                  iVar36 = func_0x000141491e21(lVar25,local_1f98,uVar10,local_9f98);
                  puVar35 = puVar13 + -6;
                  if ((iVar36 != 0) && (puVar35 = puVar13 + -6, local_9f98[0] == local_a028[0])) {
                    *(ulonglong *)(puVar13 + -8) = (ulonglong)local_a028[0];
                    *(undefined8 *)(puVar13 + -10) = 0x1407a75b0;
                    func_0x000141690a99(lVar25);
                    *(undefined8 *)(puVar13 + -10) = 0x1407a75c4;
                    FUN_1407b4700(local_5e38,0,0xa6e);
                    local_9f80 = local_a028[0];
                    local_9fb8[0] = 0;
                    local_9ff8 = 0;
                    *puVar13 = 0xf0000000;
                    *(undefined8 *)(puVar13 + -10) = 0x1407a75ee;
                    uVar40 = FUN_1403c4329(local_9fb8,0,0,0x18);
                    return uVar40;
                  }
                }
                uVar19 = 0x140f903e8;
              }
              else {
                uVar19 = 0x140f903d0;
                puVar35 = puVar13 + -4;
              }
            }
            uVar45 = 0;
            *(undefined8 *)((longlong)puVar35 + -8) = 0x1407a7b45;
            uVar40 = func_0x000141596bc4(0,uVar19,0x140f901b8,0x10);
            *(undefined1 *)(uVar40 - 0x75) = uVar45;
            return uVar40;
          }
          *(undefined8 *)(puVar13 + -4) = 0x1407a7485;
          uVar19 = func_0x0001419c3fcf();
          uVar45 = *puVar32;
          *(undefined8 *)(puVar13 + -4) = 0x1407a7494;
          uVar19 = FUN_14078aae0(local_9048,
                                 CONCAT71((int7)((ulonglong)uVar19 >> 8),uVar45) & 0xffffffff);
          *(undefined8 *)(puVar13 + -4) = 0x1407a74ab;
          FUN_1407adba0(local_9648,0x140f90380,uVar19);
          *(undefined8 *)(puVar13 + -4) = 0x1407a74b8;
          FUN_1407ac130(local_9048);
          *(undefined8 *)(puVar13 + -4) = 0x1407a74c4;
          uVar19 = FUN_1407ac0c0(local_9648);
          *(undefined8 *)(puVar13 + -4) = 0x1407a74da;
          FUN_1403b76ee(0,uVar19,0x140f901b8,0x10);
          *(undefined8 *)(puVar13 + -2) = 0x1407a74e7;
          FUN_1407ac130(local_9648);
          *(undefined8 *)(puVar13 + -2) = 0x1407a7b54;
          uVar10 = FUN_1407a3510();
          uVar40 = (ulonglong)uVar10;
          if ((*(char *)(puVar13 + 0x19) == '\0') || (uVar10 != 0)) goto LAB_1407a534c;
          goto LAB_1407a5345;
        }
        if (*(char *)(puVar13 + 0x19) == '\0') {
          _Source = (char **)(ulonglong)*(byte *)((longlong)puVar13 + 0x62);
          cVar46 = *(char *)(puVar13 + 0x18);
          cVar47 = *(char *)((longlong)puVar13 + 0x61);
          if (((*(byte *)((longlong)puVar13 + 0x62) == 0) && (cVar46 == '\0')) && (cVar47 == '\0'))
          {
            *(undefined8 *)(puVar13 + -2) = 0x1407a57c4;
            func_0x000141a07aec(0,0x140f92c70,0x140f92b20,0x10);
            pcVar1 = (code *)swi(3);
            uVar40 = (*pcVar1)();
            return uVar40;
          }
LAB_1407a581a:
          if (cVar49 != '\0') {
LAB_1407a581f:
            bVar7 = *(byte *)((longlong)puVar13 + 0x62);
            _Source = (char **)(ulonglong)bVar7;
            if (*(char *)(puVar13 + 0x18) == '\0') {
              uVar10 = (uint)(bVar7 != 0);
              puVar13[0x1c] = uVar10;
              *(undefined1 *)(puVar13 + 0x18) = 1;
            }
            else {
              uVar10 = puVar13[0x1c];
            }
            if (*(char *)((longlong)puVar13 + 0x61) == '\0') {
              uVar40 = uVar39 & 0xffffffff;
              local_a038[0] = (uint)uVar39;
              *(undefined1 *)((longlong)puVar13 + 0x61) = 1;
            }
            else {
              uVar40 = (ulonglong)local_a038[0];
            }
            if (2 < uVar10) {
              *(ulonglong *)(puVar13 + -2) = uVar40;
              *(undefined8 *)(puVar13 + -4) = 0x1407a6b12;
              uVar19 = func_0x000141666867(0,0x140f92ca0,0x140f92b20,0x10);
              *(undefined8 *)(puVar13 + -4) = uVar19;
              *(undefined8 *)(puVar13 + -6) = 0x1407a6b1a;
              func_0x0001419b082d(0);
              pcVar1 = (code *)swi(3);
              uVar40 = (*pcVar1)();
              return uVar40;
            }
            if ((bVar7 != 0) && (uVar10 != 1)) {
              *(ulonglong *)(puVar13 + -2) = uVar40;
              *(undefined8 *)(puVar13 + -4) = 0x1407a6aed;
              uVar19 = func_0x000141a46d82(0,0x140f92cc0,0x140f92b20,0x10);
              *(undefined8 *)(puVar13 + -4) = uVar19;
              *(undefined8 *)(puVar13 + -6) = 0x1407a6af5;
              func_0x000141529b26(0);
              pcVar1 = (code *)swi(3);
              uVar40 = (*pcVar1)();
              return uVar40;
            }
            if ((int)uVar40 < 0) {
              cVar46 = '\x10';
              iVar11 = 0x40f92b20;
              cVar49 = -0x10;
              *(ulonglong *)(puVar13 + -2) = uVar40;
              *(undefined8 *)(puVar13 + -4) = 0x1407a6b4e;
              func_0x0001413d9113(0);
              cVar47 = (char)pcVar12;
              cVar50 = '\0';
              *(undefined8 *)(puVar13 + -4) = 0x1407a6b55;
              uVar19 = func_0x0001414d240f(0);
              iVar36 = _DAT_141154cf6;
              if (cVar49 != '\0') {
                iVar36 = iVar11;
              }
              _DAT_141154cf6 = (int)puVar32;
              iVar42 = (int)CONCAT71((int7)((ulonglong)uVar19 >> 8),((char)uVar19 + '4') - cVar50);
              if ((cVar47 == '\0') && (iVar42 = _DAT_141154ce5, _DAT_141154ce5 == 0)) {
                iVar42 = _DAT_141154cf6;
              }
              _DAT_141154ce5 = iVar42;
              if (cVar46 == '\0') {
                if ((cVar49 != '\0') && (iVar11 != _DAT_141154cf6)) {
                  DAT_141154be6 = (char)param_1;
                }
              }
              else {
                *(undefined8 *)(puVar13 + -4) = 0x1407a6ba3;
                strncpy(&DAT_141154be6,local_8128,0xfe);
                DAT_141154ce4 = (char)param_1;
                iVar36 = _DAT_141154cf6;
              }
              _DAT_141154cf6 = iVar36;
              if (_DAT_141154cf6 == 2) {
                *(undefined8 *)(puVar13 + -4) = 0x1407a6bd6;
                cVar49 = FUN_14079a790();
                if (cVar49 == '\0') {
                  lVar25 = 0;
                  cVar49 = '\x01';
                  *(undefined8 *)(puVar13 + -4) = 0x1407a6bf5;
                  pcVar12 = (char *)func_0x0001417110b5(0,0x140f92dd8,0x140f92dd0,0x10);
                  if (lVar25 == 1 || cVar49 == '\0') {
                    local_9fb8[0] = 0x1407a6bfd;
                    func_0x0001418aea18();
                    pcVar1 = (code *)swi(3);
                    uVar40 = (*pcVar1)();
                    return uVar40;
                  }
                  *pcVar12 = *pcVar12 + (char)pcVar12;
                    /* WARNING: Bad instruction - Truncating control flow here */
                  halt_baddata();
                }
              }
              *(undefined8 *)(puVar13 + -4) = 0x1407a6c04;
              uVar19 = FUN_140790010();
              uVar40 = 0;
              *(undefined8 *)(puVar13 + -4) = 0x1407a6c13;
              FUN_14079a1e0(uVar19);
              puVar35 = puVar13 + -2;
              goto code_r0x0001407a6c13;
            }
            cVar46 = *(char *)(puVar13 + 0x18);
            cVar47 = *(char *)((longlong)puVar13 + 0x61);
          }
          cVar50 = (char)_Source;
          if ((((cVar50 != '\0') || (cVar46 != '\0')) || (cVar47 != '\0')) && (cVar49 == '\0')) {
LAB_1407a5899:
            cVar49 = (char)((ulonglong)_Source >> 8);
            *(undefined8 *)(puVar13 + -2) = 0x1407a58a5;
            FUN_14078fc90(0x140f92d10);
            if ((int)_DAT_141154d10 < 0) {
              *(undefined8 *)(puVar13 + -2) = 0x1407a58bb;
              func_0x000141462910(0x140f8d130);
              uVar10 = in(0x83);
              *(undefined8 *)(puVar13 + -2) =
                   *(undefined8 *)((longlong)puVar13 + ((ulonglong)uVar10 - 0x58));
              local_9f9b = local_9f9b + cVar49;
              *(undefined8 *)(puVar13 + -4) = 0x1407a58d1;
              DAT_7410a80b74fff883 = func_0x0001419088a0(0x140f8d148);
                    /* WARNING: Bad instruction - Truncating control flow here */
              halt_baddata();
            }
            uVar19 = 0x140f8e3d8;
            if (_DAT_141154d10 == 1) {
              uVar19 = 0x140f8e3b8;
            }
            *(undefined8 *)(puVar13 + 0xc) = 0;
            puVar13[10] = 0x80;
            puVar13[8] = 3;
            uVar40 = 0;
            *(undefined8 *)(puVar13 + -2) = 0x1407a592c;
            pcVar16 = (char *)func_0x000141acf8fd(uVar19,0x80000000,7);
            uVar10 = *(uint *)(pcVar16 + -0x75);
            _DAT_141154980 = _DAT_141154980 - 1;
            *pcVar16 = *pcVar16 + (char)pcVar16;
            *(undefined8 *)(puVar13 + -2) = 0x1407a593f;
            uVar19 = func_0x00014194a8f2((uint)uVar19 | uVar10);
            pcVar16 = (char *)CONCAT71((int7)((ulonglong)uVar19 >> 8),DAT_1e45958d4cc88b44);
            *pcVar16 = *pcVar16 + DAT_1e45958d4cc88b44;
            do {
              pcVar12 = pcVar12 + -1;
              uVar15 = (uVar40 & 0xffffffff) / 10;
              *pcVar12 = (char)uVar40 + (char)uVar15 * -10 + '0';
              uVar40 = uVar15;
            } while ((int)uVar15 != 0);
            pppppuVar41 = (undefined8 *****)0x0;
            local_99b8 = 0;
            uStack_99b0 = 0xf;
            local_99c8[0] = (undefined8 *****)0x0;
            if (pcVar12 != local_8173) {
              *(undefined8 *)(puVar13 + -2) = 0x1407a59cd;
              FUN_1407ad020(local_99c8,pcVar12,local_8173 + -(longlong)pcVar12);
            }
            if (uStack_99b0 - local_99b8 < 0x1a) {
              *(undefined8 *)(puVar13 + 10) = 0x1a;
              *(undefined8 *)(puVar13 + 8) = 0x140f90380;
              *(undefined8 *)(puVar13 + -2) = 0x1407a5a93;
              pppppuVar41 = (undefined8 *****)FUN_1407b0420(local_99c8,0x1a);
            }
            else {
              pppppuVar38 = local_99c8;
              if (0xf < uStack_99b0) {
                pppppuVar38 = (undefined8 *****)local_99c8[0];
              }
              if ((pppppuVar38 < (undefined8 *****)0x140f9039a) &&
                 ((undefined1 *)0x140f9037f < (undefined1 *)((longlong)pppppuVar38 + local_99b8))) {
                if ((undefined8 *****)0x140f90380 < pppppuVar38) {
                  pppppuVar41 = pppppuVar38 + -0x281f2070;
                }
              }
              else {
                pppppuVar41 = (undefined8 *****)0x1a;
              }
              lVar25 = local_99b8 + 1;
              *(undefined8 *)(puVar13 + -2) = 0x1407a5a4d;
              local_99b8 = local_99b8 + 0x1a;
              FUN_1407b48f0((undefined1 *)((longlong)pppppuVar38 + 0x1a),pppppuVar38,lVar25);
              *(undefined8 *)(puVar13 + -2) = 0x1407a5a5b;
              FUN_1407b48f0(pppppuVar38,0x140f90380,pppppuVar41);
              *(undefined8 *)(puVar13 + -2) = 0x1407a5a71;
              FUN_1407b48f0((undefined1 *)((longlong)pppppuVar38 + (longlong)pppppuVar41),
                            (undefined1 *)((longlong)pppppuVar41 + 0x140f9039a),
                            0x1a - (longlong)pppppuVar41);
              pppppuVar41 = local_99c8;
            }
            uVar10 = *(uint *)pppppuVar41;
            local_9868 = uVar10;
            uStack_9864 = *(undefined4 *)((longlong)pppppuVar41 + 4);
            uStack_9860 = *(undefined4 *)(pppppuVar41 + 1);
            uStack_985c = *(undefined4 *)((longlong)pppppuVar41 + 0xc);
            local_9858 = pppppuVar41[2];
            pppuStack_9850 = pppppuVar41[3];
            pppppuVar41[2] = (undefined8 ****)0x0;
            pppppuVar41[3] = (undefined8 ****)0xf;
            *(undefined1 *)pppppuVar41 = 0;
            if (0xf < uStack_99b0) {
              ppppuVar22 = (undefined8 ****)(uStack_99b0 + 1);
              if ((undefined8 ****)0xfff < ppppuVar22) {
                ppppuVar22 = (undefined8 ****)(uStack_99b0 + 0x28);
                ppppuVar21 = (undefined8 ****)local_99c8[0][-1];
                puVar35 = puVar13;
                if ((undefined1 *)0x1f <
                    (undefined1 *)((longlong)local_99c8[0] + (-8 - (longlong)ppppuVar21)))
                goto LAB_1407aa704;
              }
              *(undefined8 *)(puVar13 + -2) = 0x1407a5af8;
              thunk_FUN_1407c68b0(uVar10,ppppuVar22);
            }
            local_99b8 = 0;
            uStack_99b0 = 0xf;
            local_99c8[0] = (undefined8 ****)((ulonglong)local_99c8[0] & 0xffffffffffffff00);
            puVar23 = &local_9868;
            if ((undefined8 ****)0xf < pppuStack_9850) {
              puVar23 = (uint *)CONCAT44(uStack_9864,local_9868);
            }
            puVar35 = puVar13 + -2;
            *(undefined8 **)(puVar13 + -2) = local_9fb8;
            *(undefined8 *)(puVar13 + -4) = 0x1407a5b3d;
            func_0x00014159478f(0,puVar23,0x140f901b8,0x10);
            if ((undefined8 ****)0xf < pppuStack_9850) {
              if (0xfff < (longlong)pppuStack_9850 + 1U) {
                ppppuVar22 = (undefined8 ****)(pppuStack_9850 + 5);
                ppppuVar21 = *(undefined8 *****)(CONCAT44(uStack_9864,local_9868) + -8);
                if (0x1f < (CONCAT44(uStack_9864,local_9868) - (longlong)ppppuVar21) - 8U)
                goto LAB_1407aa704;
              }
              *(undefined8 *)(puVar13 + -4) = 0x1407a5b7e;
              thunk_FUN_1407c68b0();
            }
            local_9858 = (undefined8 ***)0x0;
            pppuStack_9850 = (undefined8 ***)0xf;
            local_9868 = local_9868 & 0xffffff00;
            *(undefined8 *)(puVar13 + -4) = 0x1407a73d8;
            FUN_14078ff10(0x140f92d28,0);
            *(undefined8 *)(puVar13 + -4) = 0x1407a73e6;
            FUN_14078ff10(0x140f92d48,0);
            *(undefined8 *)(puVar13 + -4) = 0x1407a7401;
            uVar52 = func_0x0001419036c9(0,0x140f92d78,0x140f92b20,0x10);
            local_9fb8[0] = 0x1407a7409;
            uVar45 = func_0x0001418d65a9(uVar52,0x33);
            *(undefined1 *)pppppuVar38 = uVar45;
            pcVar1 = (code *)swi(3);
            uVar40 = (*pcVar1)();
            return uVar40;
          }
          bVar7 = *(byte *)((longlong)puVar13 + 99);
          uVar40 = (ulonglong)bVar7;
          bVar48 = (char)bVar7 < '\0';
          bVar43 = (POPCOUNT(bVar7) & 1U) == 0;
          bVar51 = true;
          if (bVar7 == 0) {
LAB_1407a7b6e:
            *(undefined8 *)(puVar13 + -2) = 0x140f92e44;
            *(ulonglong *)(puVar13 + -4) =
                 (ulonglong)(in_NT & 1) * 0x4000 | (ulonglong)(in_IF & 1) * 0x200 |
                 (ulonglong)(in_TF & 1) * 0x100 | (ulonglong)bVar48 * 0x80 |
                 (ulonglong)bVar51 * 0x40 | (ulonglong)(in_AF & 1) * 0x10 | (ulonglong)bVar43 * 4 |
                 (ulonglong)(in_ID & 1) * 0x200000 | (ulonglong)(in_VIP & 1) * 0x100000 |
                 (ulonglong)(in_VIF & 1) * 0x80000 | (ulonglong)(in_AC & 1) * 0x40000;
            *(char ***)(puVar13 + -6) = _Source;
            uVar19 = *(undefined8 *)(puVar13 + -2);
            *(undefined8 *)(puVar13 + -2) = 0x5add95f5;
            *(undefined8 *)(puVar13 + -8) = *(undefined8 *)(puVar13 + -4);
            *(undefined8 *)(puVar13 + -4) = 0x1407a7b9f;
            uVar40 = func_0x000141e68765(uVar19);
            *(longlong *)(puVar13 + 0xc) = *(longlong *)(puVar13 + 0xc) + -0x100318;
            *(undefined8 *)(puVar13 + -4) = *(undefined8 *)(puVar13 + 10);
            return uVar40;
          }
          bVar48 = cVar49 < '\0';
          bVar51 = cVar49 == '\0';
          bVar43 = (POPCOUNT(cVar49) & 1U) == 0;
          if (!bVar51) goto LAB_1407a7b6e;
          bVar48 = cVar50 < '\0';
          bVar51 = cVar50 == '\0';
          bVar43 = (POPCOUNT(cVar50) & 1U) == 0;
          if (!bVar51) goto LAB_1407a7b6e;
          goto LAB_1407a742d;
        }
        uVar39 = 0x140f92b20;
        _Source = (char **)0x140f92c40;
        puVar31 = puVar13 + -2;
        *(ulonglong *)(puVar13 + -2) = uVar15;
        *(undefined8 *)(puVar13 + -4) = 0x1407a569e;
        func_0x000141a64662();
        bVar51 = false;
        uVar45 = 1;
        *(undefined8 *)(puVar13 + -4) = 0x1407a56a5;
        func_0x0001417205d8();
        puVar13 = puVar13 + -2;
        puVar35 = puVar31;
        if (bVar51) {
LAB_1407a56a7:
          *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a56c2;
          func_0x0001414d82e1(0,0x140f92b30,0x140f92b20,0x10);
          *(undefined **)((longlong)puVar13 + -8) = &UNK_1407a56ca;
          uVar40 = func_0x0001418dfada(0);
          return uVar40;
        }
      } while( true );
    }
    *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a533e;
    uVar10 = FUN_1407a2a90();
    uVar40 = (ulonglong)uVar10;
    if (bVar43) {
LAB_1407a5345:
      *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a534a;
      FUN_14079a100();
    }
  }
  else {
    uVar40 = (ulonglong)local_a038[0];
  }
LAB_1407a534c:
  *(undefined8 *)((longlong)puVar13 + -8) = 0x1407a535b;
  return uVar40;
  while( true ) {
    *(undefined8 *)(puVar33 + -0x10) = 0xffffffffffffffff;
    *(undefined **)(puVar33 + -0x18) = &UNK_1407a6c50;
    func_0x0001419a0a34(100);
    uVar10 = (int)uVar40 + 1;
    uVar40 = (ulonglong)uVar10;
    puVar35 = (undefined4 *)(puVar33 + -0x10);
    if (2 < (int)uVar10) break;
code_r0x0001407a6c13:
    puVar33 = (undefined1 *)puVar35;
    *(undefined8 *)(puVar33 + 0x30) = 0;
    *(undefined4 *)(puVar33 + 0x28) = 0x80;
    *(undefined4 *)(puVar33 + 0x20) = 2;
    *(ulonglong *)(puVar33 + -8) = uVar40;
    *(undefined **)(puVar33 + -0x10) = &UNK_1407a6c3a;
    lVar17 = func_0x000141998a2c(uVar19,0x40000000,1);
    if (lVar17 != -1) {
      lVar17 = lVar25;
      puVar5 = auStack_9d88;
      puVar6 = (undefined8 *)&DAT_141154980;
      do {
        puVar24 = puVar6;
        puVar20 = puVar5;
        uVar19 = puVar24[1];
        *puVar20 = *puVar24;
        puVar20[1] = uVar19;
        uVar19 = puVar24[3];
        puVar20[2] = puVar24[2];
        puVar20[3] = uVar19;
        uVar19 = puVar24[5];
        puVar20[4] = puVar24[4];
        puVar20[5] = uVar19;
        uVar19 = puVar24[7];
        puVar20[6] = puVar24[6];
        puVar20[7] = uVar19;
        uVar19 = puVar24[9];
        puVar20[8] = puVar24[8];
        puVar20[9] = uVar19;
        uVar19 = puVar24[0xb];
        puVar20[10] = puVar24[10];
        puVar20[0xb] = uVar19;
        uVar19 = puVar24[0xd];
        puVar20[0xc] = puVar24[0xc];
        puVar20[0xd] = uVar19;
        uVar19 = puVar24[0xf];
        puVar20[0xe] = puVar24[0xe];
        puVar20[0xf] = uVar19;
        lVar17 = lVar17 + -1;
        puVar5 = puVar20 + 0x10;
        puVar6 = puVar24 + 0x10;
      } while (lVar17 != 0);
      uVar19 = puVar24[0x11];
      puVar20[0x10] = puVar24[0x10];
      puVar20[0x11] = uVar19;
      uVar19 = puVar24[0x13];
      puVar20[0x12] = puVar24[0x12];
      puVar20[0x13] = uVar19;
      uVar19 = puVar24[0x15];
      puVar20[0x14] = puVar24[0x14];
      puVar20[0x15] = uVar19;
      uVar19 = puVar24[0x17];
      puVar20[0x16] = puVar24[0x16];
      puVar20[0x17] = uVar19;
      uVar19 = puVar24[0x19];
      puVar20[0x18] = puVar24[0x18];
      puVar20[0x19] = uVar19;
      uVar52 = *(undefined4 *)((longlong)puVar24 + 0xd4);
      uVar2 = *(undefined4 *)(puVar24 + 0x1b);
      uVar3 = *(undefined4 *)((longlong)puVar24 + 0xdc);
      *(undefined4 *)(puVar20 + 0x1a) = *(undefined4 *)(puVar24 + 0x1a);
      *(undefined4 *)((longlong)puVar20 + 0xd4) = uVar52;
      *(undefined4 *)(puVar20 + 0x1b) = uVar2;
      *(undefined4 *)((longlong)puVar20 + 0xdc) = uVar3;
      uVar52 = *(undefined4 *)((longlong)puVar24 + 0xe4);
      uVar2 = *(undefined4 *)(puVar24 + 0x1d);
      uVar3 = *(undefined4 *)((longlong)puVar24 + 0xec);
      *(undefined4 *)(puVar20 + 0x1c) = *(undefined4 *)(puVar24 + 0x1c);
      *(undefined4 *)((longlong)puVar20 + 0xe4) = uVar52;
      *(undefined4 *)(puVar20 + 0x1d) = uVar2;
      *(undefined4 *)((longlong)puVar20 + 0xec) = uVar3;
      puVar20[0x1e] = puVar24[0x1e];
      *(undefined2 *)(puVar20 + 0x1f) = *(undefined2 *)(puVar24 + 0x1f);
      *(undefined **)(puVar33 + -0x10) = &UNK_1407a6dac;
      FUN_1407b4700(auStack_652e,0,0x6f4);
      puVar5 = auStack_68a8;
      puVar6 = auStack_9d88;
      do {
        puVar24 = puVar6;
        puVar20 = puVar5;
        uVar19 = puVar24[1];
        *puVar20 = *puVar24;
        puVar20[1] = uVar19;
        uVar19 = puVar24[3];
        puVar20[2] = puVar24[2];
        puVar20[3] = uVar19;
        uVar19 = puVar24[5];
        puVar20[4] = puVar24[4];
        puVar20[5] = uVar19;
        uVar19 = puVar24[7];
        puVar20[6] = puVar24[6];
        puVar20[7] = uVar19;
        uVar19 = puVar24[9];
        puVar20[8] = puVar24[8];
        puVar20[9] = uVar19;
        uVar19 = puVar24[0xb];
        puVar20[10] = puVar24[10];
        puVar20[0xb] = uVar19;
        uVar19 = puVar24[0xd];
        puVar20[0xc] = puVar24[0xc];
        puVar20[0xd] = uVar19;
        uVar19 = puVar24[0xf];
        puVar20[0xe] = puVar24[0xe];
        puVar20[0xf] = uVar19;
        lVar25 = lVar25 + -1;
        puVar5 = puVar20 + 0x10;
        puVar6 = puVar24 + 0x10;
      } while (lVar25 != 0);
      uVar19 = puVar24[0x11];
      puVar20[0x10] = puVar24[0x10];
      puVar20[0x11] = uVar19;
      uVar19 = puVar24[0x13];
      puVar20[0x12] = puVar24[0x12];
      puVar20[0x13] = uVar19;
      uVar19 = puVar24[0x15];
      puVar20[0x14] = puVar24[0x14];
      puVar20[0x15] = uVar19;
      uVar19 = puVar24[0x17];
      puVar20[0x16] = puVar24[0x16];
      puVar20[0x17] = uVar19;
      uVar19 = puVar24[0x19];
      puVar20[0x18] = puVar24[0x18];
      puVar20[0x19] = uVar19;
      uVar52 = *(undefined4 *)((longlong)puVar24 + 0xd4);
      uVar2 = *(undefined4 *)(puVar24 + 0x1b);
      uVar3 = *(undefined4 *)((longlong)puVar24 + 0xdc);
      *(undefined4 *)(puVar20 + 0x1a) = *(undefined4 *)(puVar24 + 0x1a);
      *(undefined4 *)((longlong)puVar20 + 0xd4) = uVar52;
      *(undefined4 *)(puVar20 + 0x1b) = uVar2;
      *(undefined4 *)((longlong)puVar20 + 0xdc) = uVar3;
      uVar52 = *(undefined4 *)((longlong)puVar24 + 0xe4);
      uVar2 = *(undefined4 *)(puVar24 + 0x1d);
      uVar3 = *(undefined4 *)((longlong)puVar24 + 0xec);
      *(undefined4 *)(puVar20 + 0x1c) = *(undefined4 *)(puVar24 + 0x1c);
      *(undefined4 *)((longlong)puVar20 + 0xe4) = uVar52;
      *(undefined4 *)(puVar20 + 0x1d) = uVar2;
      *(undefined4 *)((longlong)puVar20 + 0xec) = uVar3;
      puVar20[0x1e] = puVar24[0x1e];
      *(undefined2 *)(puVar20 + 0x1f) = *(undefined2 *)(puVar24 + 0x1f);
      uStack_a02c = 0x37a;
      auStack_9fc8[0] = 0;
      uStack_a008 = 0;
      *(undefined4 *)(puVar33 + 0x18) = 0xf0000000;
      *(undefined **)(puVar33 + -0x10) = &UNK_1407a6e83;
      func_0x0001415c653f(auStack_9fc8,0,0,0x18);
      local_9f48._0_5_ = (uint5)(uint)local_9f48;
      *(undefined **)(puVar33 + -0x10) = &UNK_1407a6e8e;
      uVar52 = func_0x000141610a9f();
      *(undefined **)(puVar33 + -0x10) = &UNK_1407a6e9c;
      uVar19 = FUN_14078aae0(auStack_90e8,uVar52);
      *(undefined **)(puVar33 + -0x10) = &UNK_1407a6eb3;
      FUN_1407adba0(auStack_96e8,0x140f902c8,uVar19);
      *(undefined **)(puVar33 + -0x10) = &UNK_1407a6ec0;
      FUN_1407ac130(auStack_90e8);
      *(undefined **)(puVar33 + -0x10) = &UNK_1407a6ecc;
      uVar19 = FUN_1407ac0c0(auStack_96e8);
      *(undefined8 **)(puVar33 + -0x10) = local_9fb8;
      *(undefined **)(puVar33 + -0x18) = &UNK_1407a6ee2;
      uVar19 = func_0x0001416990fa(0,uVar19,0x140f901b8,0x10);
      puVar34 = puVar33 + -0x18;
      *(undefined8 *)(puVar33 + -0x18) = uVar19;
      *(undefined **)(puVar33 + -0x20) = &UNK_1407a6eeb;
      func_0x000141a3d496(0x85);
      *(undefined **)(puVar33 + -0x20) = &UNK_1407a6ef7;
      FUN_1407ac130(auStack_96e8);
      goto code_r0x0001407a7377;
    }
  }
  *(undefined **)(puVar33 + -0x18) = &UNK_1407a6c61;
  uVar52 = func_0x0001419829dd();
  *(undefined1 **)(puVar33 + -0x18) = puVar33 + -0x10;
  *(undefined **)(puVar33 + -0x20) = &UNK_1407a6c70;
  uVar19 = FUN_14078aae0(auStack_9108,uVar52);
  *(undefined **)(puVar33 + -0x20) = &UNK_1407a6c87;
  uVar19 = FUN_1407adba0(auStack_9128,0x140f902a8,uVar19);
  *(undefined **)(puVar33 + -0x20) = &UNK_1407a6c9e;
  FUN_1407ad770(auStack_9708,uVar19,0x140f90278);
  *(undefined **)(puVar33 + -0x20) = &UNK_1407a6cab;
  FUN_1407ac130(auStack_9128);
  *(undefined **)(puVar33 + -0x20) = &UNK_1407a6cb8;
  FUN_1407ac130(auStack_9108);
  *(undefined **)(puVar33 + -0x20) = &UNK_1407a6cc4;
  uVar19 = FUN_1407ac0c0(auStack_9708);
  puVar34 = puVar33 + -0x20;
  *(undefined8 *)(puVar33 + -0x20) = uVar19;
  *(undefined **)(puVar33 + -0x28) = &UNK_1407a6cda;
  func_0x0001416a1f98(0,uVar19,0x140f901b8,0x10);
  *(undefined **)(puVar33 + -0x28) = &UNK_1407a6ce6;
  FUN_1407ac130(auStack_9708);
code_r0x0001407a7377:
  *(undefined **)(puVar34 + -8) = &UNK_1407a7392;
  func_0x0001415923d9(0,0x140f92df8,0x140f901b8,0x10);
                    /* WARNING: Bad instruction - Truncating control flow here */
  halt_baddata();
}


// ==== FUN_1407a1880 @ 1407a1880 ====

/* WARNING: Control flow encountered bad instruction data */
/* WARNING: Instruction at (ram,0x0001407a1af0) overlaps instruction at (ram,0x0001407a1aed)
    */
/* WARNING: Function: __security_check_cookie replaced with injection: security_check_cookie */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined1 FUN_1407a1880(void)

{
  char *pcVar1;
  undefined8 ***pppuVar2;
  byte bVar3;
  undefined1 uVar4;
  uint uVar5;
  int iVar6;
  int iVar7;
  longlong lVar8;
  ulonglong uVar9;
  undefined8 uVar10;
  longlong lVar11;
  undefined8 uVar12;
  undefined8 ****ppppuVar13;
  longlong unaff_RBX;
  undefined1 *puVar14;
  undefined1 *puVar15;
  undefined1 *puVar16;
  undefined1 *puVar17;
  undefined1 *puVar18;
  undefined8 unaff_RDI;
  undefined8 uVar19;
  bool bVar20;
  undefined1 auStack_98 [64];
  undefined4 local_58 [2];
  undefined8 ***local_50 [2];
  ulonglong local_40;
  ulonglong local_38;
  ulonglong local_30;
  
  puVar14 = auStack_98;
  local_30 = _DAT_140f9e010 ^ (ulonglong)auStack_98;
  local_40 = 0;
  local_38 = 0xf;
  local_50[0] = (undefined8 ****)0x0;
  FUN_1407ad180(local_50,0x140f91e48,0xb);
  FUN_1407ad180(local_50,0x140f91e58,0x11);
  FUN_1407ad180(local_50,0x140f91e70,10);
  FUN_1407ad180(local_50,0x140f91e80,0x1f);
  FUN_1407ad180(local_50,0x140f91ea0,0x15);
  FUN_1407ad180(local_50,0x140f91eb8,0xb);
  FUN_1407ad180(local_50,0x140f91ec8,8);
  FUN_1407ad180(local_50,0x140f91ed8,0x12);
  FUN_1407ad180(local_50,0x140f91ef0,0x13);
  FUN_1407ad180(local_50,0x140f91f10,0x83);
  FUN_1407ad180(local_50,0x140f91f98,0x1a);
  FUN_1407ad180(local_50,0x140f91fb4,3);
  FUN_1407ad180(local_50,0x140f91fb8,0x29);
  FUN_1407ad180(local_50,0x140f91fe8,0x23);
  FUN_1407ad180(local_50,0x140f92010,0x3a);
  FUN_1407ad180(local_50,0x140f92050,0x39);
  FUN_1407ad180(local_50,0x140f92090,0x35);
  FUN_1407ad180(local_50,0x140f920c8,0x39);
  FUN_1407ad180(local_50,0x140f92108,0x35);
  FUN_1407ad180(local_50,0x140f92140,0x39);
  FUN_1407ad180(local_50,0x140f92180,0x39);
  FUN_1407ad180(local_50,0x140f921c0,0x30);
  FUN_1407ad180(local_50,0x140f921f8,0x33);
  FUN_1407ad180(local_50,0x140f92230,0x3b);
  FUN_1407ad180(local_50,0x140f92270,0x33);
  FUN_1407ad180(local_50,0x140f922a8,0x3b);
  FUN_1407ad180(local_50,0x140f922e8,0x28);
  FUN_1407ad180(local_50,0x140f92318,0xb);
  iVar7 = 0;
  puVar17 = auStack_98;
  if (-1 < _DAT_141154d10) goto LAB_1407a1b3a;
  do {
    *(undefined8 *)(puVar14 + -8) = 0x1407a1b0c;
    bVar3 = func_0x000141401699(0x140f8d130);
    *(char *)(unaff_RBX + 0x474fff8) = *(char *)(unaff_RBX + 0x474fff8) + bVar3;
    puVar18 = puVar14;
    if ((bVar3 & 0x10) == 0) {
      *(undefined8 *)(puVar14 + -8) = unaff_RDI;
      *(undefined8 *)(puVar14 + -0x10) = 0x1407a1b23;
      uVar5 = func_0x0001418761ab(0x140f8d148);
      puVar18 = puVar14 + -8;
      if ((uVar5 == 0xffffffff) ||
         (puVar18 = puVar14 + -8, puVar17 = puVar14 + -8, _DAT_141154d10 = 1, (uVar5 & 0x10) == 0))
      goto LAB_1407a1b31;
    }
    else {
LAB_1407a1b31:
      puVar17 = puVar18;
      _DAT_141154d10 = iVar7;
    }
LAB_1407a1b3a:
    uVar10 = 0x140f8e548;
    if (_DAT_141154d10 == 1) {
      uVar10 = 0x140f8e528;
    }
    puVar15 = puVar17 + -8;
    puVar14 = puVar17 + -8;
    *(undefined1 **)(puVar17 + -8) = &stack0xffffffffffffffd8;
    *(undefined8 *)(puVar17 + -0x10) = 0x1407a1b55;
    func_0x000141835b48(uVar10);
    bVar20 = false;
    if (-1 < _DAT_141154d10) goto LAB_1407a1b99;
    *(undefined8 *)(puVar17 + -0x10) = 0x1407a1b6b;
    lVar8 = func_0x0001416e07f2(0x140f8d130);
  } while (!bVar20);
  *(undefined8 *)(puVar17 + -0x10) = *(undefined8 *)(puVar17 + lVar8 + -0x60);
  lVar11 = 0x140f8d148;
  *(undefined8 *)(puVar17 + -0x18) = 0x1407a1b81;
  lVar8 = func_0x00014151e1b1();
  puVar15 = puVar17 + -0x18;
  *(undefined8 *)(puVar17 + -0x18) = *(undefined8 *)(lVar11 * 2 + -0x58);
  pcVar1 = (char *)(lVar8 + 1);
  *pcVar1 = *pcVar1 + (char)((ulonglong)unaff_RBX >> 8);
  if (*pcVar1 == '\0') {
    lVar8 = 0;
  }
  _DAT_141154d10 = (int)lVar8;
LAB_1407a1b99:
  lVar8 = 0x140f8e5c8;
  uVar10 = 0x140f8e5c8;
  if (_DAT_141154d10 == 1) {
    uVar10 = 0x140f8e5a8;
  }
  uVar12 = 0x80;
  *(undefined8 *)(puVar15 + -8) = 0x1407a1bbb;
  iVar6 = func_0x00014191aa43(uVar10);
  puVar17 = puVar15;
  if (iVar6 < 0) {
    *(undefined8 *)(puVar15 + -8) = 0x1407a1bd2;
    lVar11 = func_0x000141651366(0x140f8d130);
    lVar8 = 0x140f8e583;
    *(undefined8 *)(puVar15 + -8) = *(undefined8 *)(puVar15 + lVar11 + -0x58);
    *(undefined8 *)(puVar15 + -0x10) = 0x1407a1be8;
    uVar10 = func_0x00014118f7e7(0x140f8d148);
    bVar3 = in((short)uVar12);
    if (((int)CONCAT71((int7)((ulonglong)uVar10 >> 8),bVar3) == -1) ||
       (puVar17 = puVar15 + -8, iVar6 = 1, _DAT_141154d10 = 1, (bVar3 & 0x10) == 0)) {
      puVar17 = puVar15 + -8;
      iVar6 = 0;
      _DAT_141154d10 = 0;
    }
  }
  lVar11 = lVar8;
  if (iVar6 == 1) {
    lVar11 = 0x140f8e5a8;
  }
  *(undefined1 **)(puVar17 + -8) = &stack0xffffffffffffffd8;
  *(undefined8 *)(puVar17 + -0x10) = 0x1407a1c10;
  func_0x000141411062(lVar11);
  puVar18 = puVar17 + -8;
  if (_DAT_141154d10 < 0) {
    *(undefined8 *)(puVar17 + -0x10) = 0x1407a1c26;
    uVar10 = func_0x0001418c51f6(0x140f8d130);
    *(undefined1 *)(lVar8 + 0x474fff8) = 0xa8;
    *(undefined8 *)(puVar17 + -0x10) = uVar10;
    *(undefined8 *)(puVar17 + -0x18) = 0x1407a1c3d;
    uVar5 = func_0x000141addd34(0x140f8d148);
    if ((uVar5 == 0xffffffff) ||
       (puVar18 = puVar17 + -0x10, _DAT_141154d10 = 1, (uVar5 & 0x10) == 0)) {
      puVar18 = puVar17 + -0x10;
      _DAT_141154d10 = iVar7;
    }
  }
  uVar19 = 0x140f8e588;
  uVar10 = 0x140f8e588;
  if (_DAT_141154d10 == 1) {
    uVar10 = 0x140f8e568;
  }
  *(undefined8 *)(puVar18 + -8) = uVar12;
  *(undefined8 *)(puVar18 + -0x10) = 0x1407a1c72;
  iVar6 = func_0x000141446dc4(uVar10);
  uVar10 = 0x140f8e508;
  if (iVar6 != -1) {
    if (_DAT_141154d10 < 0) {
      *(undefined8 *)(puVar18 + -0x10) = 0x1407a1c9f;
      uVar5 = func_0x000141711bbd(0x140f8d130);
      if ((uVar5 == 0xffffffff) || ((uVar5 & 0x10) == 0)) {
        *(undefined **)(puVar18 + -0x10) = &UNK_1407a1cb5;
        func_0x00014153cd88(0x140f8d148,(int)uVar5 >> 0x1f);
                    /* WARNING: Bad instruction - Truncating control flow here */
        halt_baddata();
      }
      _DAT_141154d10 = 0;
    }
    lVar11 = lVar8;
    if (_DAT_141154d10 == 1) {
      lVar11 = 0x140f8e5a8;
    }
    puVar17 = puVar18 + -8;
    if (_DAT_141154d10 < 0) {
      *(longlong *)(puVar18 + -0x10) = lVar8;
      *(undefined8 *)(puVar18 + -0x18) = 0x1407a1ce8;
      uVar5 = func_0x0001414fd385(0x140f8d130);
      if ((uVar5 == 0xffffffff) || (puVar16 = puVar18 + -0x10, (uVar5 & 0x10) == 0)) {
        *(undefined8 *)(puVar18 + -0x18) = 0x140f8e588;
        *(undefined8 *)(puVar18 + -0x20) = 0x1407a1cfe;
        uVar5 = func_0x00014162217f(0x140f8d148);
        puVar16 = puVar18 + -0x18;
        if ((uVar5 != 0xffffffff) &&
           (puVar16 = puVar18 + -0x18, puVar17 = puVar18 + -0x18, _DAT_141154d10 = 1,
           (uVar5 & 0x10) != 0)) goto LAB_1407a1d15;
      }
      puVar17 = puVar16;
      _DAT_141154d10 = iVar7;
    }
LAB_1407a1d15:
    if (_DAT_141154d10 == 1) {
      uVar19 = 0x140f8e568;
    }
    *(undefined1 **)(puVar17 + -8) = &stack0xffffffffffffffd8;
    *(undefined8 *)(puVar17 + -0x10) = 0x1407a1d2e;
    func_0x00014187ab5e(uVar19,lVar11,3);
    puVar18 = puVar17 + -8;
    if (_DAT_141154d10 < 0) {
      *(undefined8 *)(puVar17 + -0x10) = uVar19;
      *(undefined8 *)(puVar17 + -0x18) = 0x1407a1d45;
      uVar5 = func_0x000141825a5d(0x140f8d130);
      if ((uVar5 == 0xffffffff) || ((uVar5 & 0x10) == 0)) {
        *(undefined8 *)(puVar17 + -0x18) = 0x1407a1d5a;
        uVar9 = func_0x0001416b30ab(0x140f8d148);
        puVar18 = puVar17 + -0x10;
        _DAT_141154d10 = 1;
        if ((uVar9 & 0x10) != 0) goto LAB_1407a1d72;
      }
      puVar18 = puVar17 + -0x10;
      _DAT_141154d10 = iVar7;
    }
LAB_1407a1d72:
    uVar19 = 0x140f8e508;
    if (_DAT_141154d10 == 1) {
      uVar19 = 0x140f8e4e8;
    }
    if (_DAT_141154d10 < 0) {
      *(undefined8 *)(puVar18 + -8) = 0x140f8d130;
      *(undefined8 *)(puVar18 + -0x10) = 0x1407a1d94;
      uVar5 = FUN_140780c70();
      if ((uVar5 == 0xffffffff) || (puVar17 = puVar18 + -8, (uVar5 & 0x10) == 0)) {
        *(undefined1 **)(puVar18 + -0x10) = &stack0xffffffffffffffd8;
        *(undefined8 *)(puVar18 + -0x18) = 0x1407a1daa;
        uVar5 = func_0x0001419874c4(0x140f8d148);
        puVar17 = puVar18 + -0x10;
        if ((uVar5 != 0xffffffff) &&
           (puVar17 = puVar18 + -0x10, puVar18 = puVar18 + -0x10, _DAT_141154d10 = 1,
           (uVar5 & 0x10) != 0)) goto LAB_1407a1dc1;
      }
      puVar18 = puVar17;
      _DAT_141154d10 = iVar7;
    }
LAB_1407a1dc1:
    if (_DAT_141154d10 == 1) {
      lVar8 = 0x140f8e5a8;
    }
    *(undefined8 *)(puVar18 + -8) = 0x140f8e508;
    *(undefined8 *)(puVar18 + -0x10) = 0x1407a1dda;
    uVar12 = uVar19;
    func_0x0001415a426d(lVar8,uVar19,3);
  }
  puVar17 = puVar18 + -8;
  if (_DAT_141154d10 < 0) {
    *(undefined8 *)(puVar18 + -0x10) = 0x140f8e508;
    *(undefined8 *)(puVar18 + -0x18) = 0x1407a1df1;
    uVar5 = func_0x0001413d2cdc(0x140f8d130);
    if ((uVar5 == 0xffffffff) || (puVar16 = puVar18 + -0x10, (uVar5 & 0x10) == 0)) {
      *(undefined8 *)(puVar18 + -0x18) = 0x1407a1e06;
      uVar5 = func_0x00014117d38c(0x140f8d148);
      *(undefined8 *)(puVar18 + -0x18) = uVar12;
      puVar16 = puVar18 + -0x18;
      if ((uVar5 != 0xffffffff) &&
         (puVar16 = puVar18 + -0x18, puVar17 = puVar18 + -0x18, _DAT_141154d10 = 1,
         (uVar5 & 0x10) != 0)) goto LAB_1407a1e1e;
    }
    puVar17 = puVar16;
    _DAT_141154d10 = iVar7;
  }
LAB_1407a1e1e:
  if (_DAT_141154d10 == 1) {
    uVar10 = 0x140f8e4e8;
  }
  *(undefined8 *)(puVar17 + 0x30) = 0;
  *(undefined4 *)(puVar17 + 0x28) = 0x80;
  *(undefined4 *)(puVar17 + 0x20) = 2;
  bVar3 = 0;
  *(undefined8 *)(puVar17 + -8) = 0x1407a1e4d;
  iVar7 = func_0x00014118a6e6(uVar10,0x40000000,0,0);
  if ((iVar7 + -0x48f88b48) - (uint)bVar3 == -1) {
    uVar4 = 0;
    puVar18 = puVar17;
  }
  else {
    local_58[0] = 0;
    ppppuVar13 = local_50;
    if (0xf < local_38) {
      ppppuVar13 = (undefined8 ****)local_50[0];
    }
    *(undefined8 *)(puVar17 + 0x20) = 0;
    uVar9 = local_40 & 0xffffffff;
    puVar18 = puVar17 + -8;
    *(longlong *)(puVar17 + -8) = lVar8;
    *(undefined8 *)(puVar17 + -0x10) = 0x1407a1e83;
    uVar4 = func_0x000141475fc3(uVar19,ppppuVar13,uVar9,local_58);
    *(undefined8 *)(puVar17 + -0x10) = 0x1407a1e8d;
    func_0x0001418db92b(uVar19);
  }
  if (0xf < local_38) {
    if (0xfff < local_38 + 1) {
      lVar8 = local_38 + 0x28;
      pppuVar2 = (undefined8 ***)local_50[0][-1];
      if (0x1f < (ulonglong)((longlong)local_50[0] + (-8 - (longlong)pppuVar2))) {
                    /* WARNING: Subroutine does not return */
        *(undefined **)(puVar18 + -8) = &UNK_1407a1efd;
        FUN_1407b8bd4(pppuVar2,lVar8);
      }
    }
    *(undefined8 *)(puVar18 + -8) = 0x1407a1ecb;
    thunk_FUN_1407c68b0();
  }
  *(undefined8 *)(puVar18 + -8) = 0x1407a1eda;
  return uVar4;
}


// ==== FUN_14078de50 @ 14078de50 ====

/* WARNING: Instruction at (ram,0x00014078df4c) overlaps instruction at (ram,0x00014078df47)
    */
/* WARNING: Control flow encountered bad instruction data */
/* WARNING: Function: __security_check_cookie replaced with injection: security_check_cookie */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 FUN_14078de50(void)

{
  char *pcVar1;
  undefined4 *puVar2;
  ulonglong uVar3;
  uint uVar4;
  undefined4 *puVar5;
  longlong lVar6;
  int iVar7;
  undefined8 uVar8;
  undefined2 uVar9;
  uint uVar10;
  ulonglong unaff_RBX;
  uint uVar11;
  undefined4 uVar12;
  undefined4 uVar13;
  undefined4 extraout_XMM0_Dc;
  undefined4 extraout_XMM0_Dd;
  undefined1 auStack_108 [16];
  uint *local_f8;
  undefined8 local_f0;
  longlong local_e8;
  longlong local_e0;
  undefined8 local_d8;
  int local_a8;
  uint local_a4;
  uint local_a0;
  undefined8 local_9c;
  uint local_94;
  undefined4 local_90;
  undefined4 uStack_8c;
  undefined4 uStack_88;
  undefined4 uStack_84;
  undefined4 local_80;
  undefined4 uStack_7c;
  undefined4 uStack_78;
  undefined4 uStack_74;
  undefined8 local_70;
  undefined8 uStack_68;
  undefined8 local_60;
  undefined8 uStack_58;
  longlong local_50 [2];
  undefined8 local_40;
  ulonglong local_38;
  ulonglong local_30;
  
  local_30 = _DAT_140f9e010 ^ (ulonglong)auStack_108;
  local_40 = 0;
  local_38 = 0xf;
  local_50[0] = 0;
  uVar13 = 0;
  FUN_1407ad020(local_50,0x140f8cf68,4);
  lVar6 = -1;
  do {
    pcVar1 = &DAT_14115c3f1 + lVar6;
    lVar6 = lVar6 + 1;
  } while (*pcVar1 != '\0');
  puVar5 = (undefined4 *)FUN_1407ad180(local_50,&DAT_14115c3f0);
  local_90 = *puVar5;
  uStack_8c = puVar5[1];
  uStack_88 = puVar5[2];
  uStack_84 = puVar5[3];
  local_80 = puVar5[4];
  uStack_7c = puVar5[5];
  uStack_78 = puVar5[6];
  uStack_74 = puVar5[7];
  *(undefined8 *)(puVar5 + 4) = 0;
  *(undefined8 *)(puVar5 + 6) = 0xf;
  *(undefined1 *)puVar5 = 0;
  if (0xf < local_38) {
    if (0xfff < local_38 + 1) {
      if (0x1f < (local_50[0] - *(longlong *)(local_50[0] + -8)) - 8U) {
                    /* WARNING: Subroutine does not return */
        FUN_1407b8bd4(*(longlong *)(local_50[0] + -8),local_38 + 0x28);
      }
    }
    thunk_FUN_1407c68b0();
  }
  local_e8._0_4_ = _DAT_14115c344;
  uVar8 = 0x140f8d160;
  while( true ) {
    if (CONCAT44(uStack_74,uStack_78) < 0x10) {
      FUN_14078cd60(uVar8);
      puVar5 = &local_90;
    }
    else {
      puVar5 = (undefined4 *)FUN_14078cd60(uVar8,CONCAT44(uStack_8c,local_90));
    }
    local_d8 = 0;
    local_e0 = CONCAT44(local_e0._4_4_,0x80);
    local_e8._0_4_ = 3;
    lVar6 = func_0x00014172c27e(puVar5,0xc0000000,3);
    LOCK();
    puVar2 = (undefined4 *)((unaff_RBX - 8) + (longlong)puVar5 * 4);
    uVar12 = *puVar2;
    *puVar2 = (int)puVar5;
    UNLOCK();
    if (lVar6 != -1) break;
    uVar8 = func_0x00014168c92a();
    iVar7 = (int)unaff_RBX + -0x3cfa7628;
    if (iVar7 != 0) {
      bRam0000000000000000 = bRam0000000000000000 + (char)iVar7;
      bRam0000000000000000 = bRam0000000000000000 >> 1 | bRam0000000000000000 * -0x80;
      uRam0000000141154898 = CONCAT44(extraout_XMM0_Dd,extraout_XMM0_Dc);
      uRam00000001411548a8 = CONCAT44(extraout_XMM0_Dd,extraout_XMM0_Dc);
      uRam00000001411548b8 = CONCAT44(extraout_XMM0_Dd,extraout_XMM0_Dc);
      uRam00000001411548c8 = CONCAT44(extraout_XMM0_Dd,extraout_XMM0_Dc);
      uRam00000001411548d8 = CONCAT44(extraout_XMM0_Dd,extraout_XMM0_Dc);
      uRam00000001411548e8 = CONCAT44(extraout_XMM0_Dd,extraout_XMM0_Dc);
      uRam00000001411548f8 = CONCAT44(extraout_XMM0_Dd,extraout_XMM0_Dc);
      uVar9 = 0xd1a8;
      _DAT_141154890 = uVar8;
      _DAT_1411548a0 = uVar8;
      _DAT_1411548b0 = uVar8;
      _DAT_1411548c0 = uVar8;
      _DAT_1411548d0 = uVar8;
      _DAT_1411548e0 = uVar8;
      _DAT_1411548f0 = uVar8;
      func_0x000141967165(&DAT_141154880,0x140f8d1a8,0x80);
      in(uVar9);
      puVar5 = &local_90;
      if (0xf < CONCAT44(uStack_74,uStack_78)) {
        puVar5 = (undefined4 *)CONCAT44(uStack_8c,local_90);
      }
      FUN_14078cd60(0x140f8d1b0,unaff_RBX & 0xffffffff,puVar5,&DAT_14115c3f0);
      uVar3 = CONCAT44(uStack_74,uStack_78);
      if (0xf < uVar3) {
        if (0xfff < uVar3 + 1) {
          lVar6 = *(longlong *)(CONCAT44(uStack_8c,local_90) + -8);
          if (0x1f < (CONCAT44(uStack_8c,local_90) - lVar6) - 8U) {
                    /* WARNING: Subroutine does not return */
            FUN_1407b8bd4(lVar6,uVar3 + 0x28);
          }
        }
        thunk_FUN_1407c68b0();
      }
      return 0;
    }
    uVar8 = 0;
  }
  local_70 = 0;
  uStack_68 = 0;
  local_60 = 0;
  uStack_58 = 0;
  local_9c._4_4_ = 0;
  local_a8 = 0;
  local_a4 = 0;
  local_a0 = 0;
  local_94 = 0;
  local_9c._0_4_ = 0;
  uVar4 = func_0x000141a4ec61(uVar12);
  local_f0 = (undefined8 *)((ulonglong)local_f0._4_4_ << 0x20);
  uVar12 = FUN_14078cf20(&local_70,0,uVar4,0);
  local_d8 = 0;
  local_e0 = (longlong)&local_9c + 4;
  local_e8 = CONCAT44(local_e8._4_4_,0x20);
  local_f0 = &local_70;
  iVar7 = func_0x0001416238dd(uVar12,_DAT_14115c36c,&local_70,0x20);
  if (iVar7 == 0) {
    uVar13 = func_0x000141a47c2c();
  }
  else {
    local_f0 = &local_9c;
    local_f8 = &local_94;
    iVar7 = FUN_14078d3f0(&local_70,&local_a8,&local_a4,&local_a0);
    if ((((iVar7 != 0) && (uVar13 = 0, local_a8 == 0)) && (local_a4 == uVar4)) && (local_a0 != 0)) {
      uVar10 = (_DAT_14115c348 ^ _DAT_14115c35c ^ uVar4) +
               (_DAT_14115c358 ^ _DAT_14115c344 ^ local_a0);
      uVar10 = ((uVar10 * 0x2000 | uVar10 >> 0x13) ^ uVar10) +
               (_DAT_14115c34c ^ _DAT_14115c360 ^ 0x9e3779b9);
      uVar11 = ((uVar10 * 0x80 | uVar10 >> 0x19) ^ uVar10) +
               (local_a0 * 0x45d9f3b ^ _DAT_14115c350 ^ _DAT_14115c364);
      uVar10 = _DAT_14115c354 ^ _DAT_14115c344 ^ 0xa53c9e1b;
      uVar10 = (uVar10 >> 0x10 ^ uVar10) * 0x7feb352d;
      local_94 = (uVar10 >> 0xf ^ uVar10) * -0x7b935975;
      local_94 = (uVar11 * 0x800 | uVar11 >> 0x15) ^ local_94 >> 0x10 ^ uVar11 ^ local_94;
      local_f8 = (uint *)CONCAT44(local_f8._4_4_,local_94);
      uVar13 = FUN_14078cf20(&local_70,1,uVar4,local_a0);
      local_9c._4_4_ = 0;
      local_a8 = 0;
      local_a4 = 0;
      local_9c._0_4_ = 0;
      local_e0 = 0;
      local_e8 = (longlong)&local_9c + 4;
      local_f0 = (undefined8 *)CONCAT44(local_f0._4_4_,0x20);
      local_f8 = (uint *)&local_70;
      func_0x0001417584bc(uVar13,_DAT_14115c36c,&local_70,0x20);
                    /* WARNING: Bad instruction - Truncating control flow here */
      halt_baddata();
    }
  }
  _DAT_141154880 = 0;
  uRam0000000141154888 = 0;
  _DAT_141154890 = 0;
  uRam0000000141154898 = 0;
  _DAT_1411548a0 = 0;
  uRam00000001411548a8 = 0;
  _DAT_1411548b0 = 0;
  uRam00000001411548b8 = 0;
  _DAT_1411548c0 = 0;
  uRam00000001411548c8 = 0;
  _DAT_1411548d0 = 0;
  uRam00000001411548d8 = 0;
  _DAT_1411548e0 = 0;
  uRam00000001411548e8 = 0;
  _DAT_1411548f0 = 0;
  uRam00000001411548f8 = 0;
  _DAT_14115c374 = uVar13;
  func_0x000141180874(&DAT_141154880,0x140f8d1dc,0x80);
                    /* WARNING: Bad instruction - Truncating control flow here */
  halt_baddata();
}


// ==== FUN_14078f060 @ 14078f060 ====

/* WARNING: Function: __security_check_cookie replaced with injection: security_check_cookie */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined8 FUN_14078f060(char *param_1,undefined4 param_2,char param_3)

{
  int iVar1;
  char *pcVar2;
  undefined8 uVar3;
  int iVar4;
  ulonglong uVar5;
  uint uVar6;
  ulonglong uVar7;
  undefined1 auStack_188 [32];
  undefined1 *local_168;
  undefined1 *local_160;
  undefined4 local_158;
  undefined4 local_150;
  int *local_148 [2];
  int local_138;
  undefined4 local_134;
  char local_130 [256];
  char local_30;
  undefined1 local_2f;
  ulonglong local_28;
  
  local_28 = _DAT_140f9e010 ^ (ulonglong)auStack_188;
  iVar4 = (int)param_3;
  FUN_1407b4700(&local_138,0,0x10c);
  if (param_1 == (char *)0x0) {
    uVar3 = 0;
  }
  else {
    uVar7 = 0;
    pcVar2 = param_1;
    uVar5 = uVar7;
    do {
      if (*pcVar2 == '\0') break;
      iVar1 = (int)uVar5;
      if (pcVar2[1] == '\0') {
        uVar5 = (ulonglong)(iVar1 + 1);
        break;
      }
      if (pcVar2[2] == '\0') {
        uVar5 = (ulonglong)(iVar1 + 2);
        break;
      }
      if (pcVar2[3] == '\0') {
        uVar5 = (ulonglong)(iVar1 + 3);
        break;
      }
      if (pcVar2[4] == '\0') {
        uVar5 = (ulonglong)(iVar1 + 4);
        break;
      }
      pcVar2 = pcVar2 + 5;
      uVar5 = (ulonglong)(iVar1 + 5U);
    } while (iVar1 + 5U < 0xff);
    local_160._0_4_ = _DAT_14115c340;
    local_168 = &DAT_14115c3f0;
    FUN_14078cd60(0x140f8d9a0,param_2,iVar4,uVar5);
    pcVar2 = local_130;
    do {
      if (pcVar2[(longlong)param_1 - (longlong)local_130] == '\0') break;
      *pcVar2 = pcVar2[(longlong)param_1 - (longlong)local_130];
      uVar6 = (int)uVar7 + 1;
      uVar7 = (ulonglong)uVar6;
      pcVar2 = pcVar2 + 1;
    } while (uVar6 < 0xff);
    local_130[uVar7] = '\0';
    local_148[0] = &local_138;
    local_2f = 0;
    local_134 = param_2;
    local_30 = param_3;
    iVar1 = FUN_14078ece0(local_148);
    if (iVar1 == 0) {
      local_150 = _DAT_14115c370;
      local_158 = _DAT_14115c378;
      local_160 = &DAT_141154900;
      local_168 = (undefined1 *)CONCAT44(local_168._4_4_,_DAT_14115c374);
      FUN_14078cd60(0x140f8d9f0,param_2,iVar4,&DAT_141154880);
      uVar3 = 0;
    }
    else if (local_138 == 0x12345678) {
      local_168 = (undefined1 *)CONCAT44(local_168._4_4_,_DAT_14115c340);
      FUN_14078cd60(0x140f8dad8,param_2,iVar4,&DAT_14115c3f0);
      uVar3 = 1;
    }
    else {
      local_160 = (undefined1 *)CONCAT44(local_160._4_4_,_DAT_14115c340);
      local_168 = &DAT_14115c3f0;
      FUN_14078cd60(0x140f8da70,local_138,param_2,iVar4);
      uVar3 = 0;
    }
  }
  return uVar3;
}


// ==== FUN_14078b650 @ 14078b650 ====

/* WARNING: Control flow encountered bad instruction data */
/* WARNING: Instruction at (ram,0x00014078b9be) overlaps instruction at (ram,0x00014078b9bd)
    */
/* WARNING: Function: __security_check_cookie replaced with injection: security_check_cookie */
/* WARNING: Type propagation algorithm not settling */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void FUN_14078b650(longlong param_1,longlong *param_2)

{
  byte bVar1;
  longlong lVar2;
  longlong lVar3;
  uint uVar4;
  char *pcVar5;
  char cVar6;
  int iVar7;
  undefined4 uVar8;
  longlong lVar9;
  ulonglong uVar10;
  int *piVar11;
  undefined8 uVar12;
  ulonglong *puVar13;
  undefined1 *puVar14;
  ulonglong *puVar15;
  uint *puVar16;
  longlong *plVar17;
  longlong unaff_RSI;
  uint uVar18;
  byte *pbVar19;
  bool bVar20;
  undefined1 uVar21;
  ulonglong auStack_ef8 [5];
  longlong lStack_ed0;
  uint local_ec8 [2];
  longlong local_ec0;
  longlong local_eb8;
  longlong local_eb0;
  uint local_ea8 [2];
  longlong local_ea0 [3];
  undefined8 *local_e88;
  undefined8 local_e40;
  undefined8 local_e38;
  undefined8 local_e30;
  int local_e28 [2];
  undefined2 local_e20;
  ushort local_e1e;
  ushort local_e1a;
  ushort local_e18;
  ushort local_e16;
  ushort local_e14;
  ushort local_e12;
  undefined8 local_e08;
  undefined8 uStack_e00;
  undefined8 local_df8;
  undefined8 uStack_df0;
  undefined8 local_de8;
  undefined8 uStack_de0;
  undefined8 local_dd8;
  undefined8 uStack_dd0;
  undefined1 local_dc8;
  byte local_db8 [304];
  undefined1 local_c88 [528];
  undefined1 local_a78 [1024];
  undefined1 local_678 [1600];
  ulonglong local_38;
  
  local_38 = _DAT_140f9e010 ^ (ulonglong)local_ea8;
  lVar2 = *param_2;
  lVar3 = param_2[1];
  local_dc8 = 0;
  local_e08 = 0;
  uStack_e00 = 0;
  local_df8 = 0;
  uStack_df0 = 0;
  local_de8 = 0;
  uStack_de0 = 0;
  local_dd8 = 0;
  uStack_dd0 = 0;
  puVar15 = (ulonglong *)local_ea8;
  if ((lVar2 != lVar3) && (puVar15 = (ulonglong *)local_ea8, lVar2 != 0)) {
    uVar18 = 0;
    local_e28[0] = 0x20;
    local_e30 = 0;
    local_e38 = 0;
    local_e88 = (undefined8 *)CONCAT44(local_e88._4_4_,0xf0000000);
    local_db8[0] = 0;
    local_db8[1] = 0;
    local_db8[2] = 0;
    local_db8[3] = 0;
    local_db8[4] = 0;
    local_db8[5] = 0;
    local_db8[6] = 0;
    local_db8[7] = 0;
    local_db8[8] = 0;
    local_db8[9] = 0;
    local_db8[10] = 0;
    local_db8[0xb] = 0;
    local_db8[0xc] = 0;
    local_db8[0xd] = 0;
    local_db8[0xe] = 0;
    local_db8[0xf] = 0;
    local_db8[0x10] = 0;
    local_db8[0x11] = 0;
    local_db8[0x12] = 0;
    local_db8[0x13] = 0;
    local_db8[0x14] = 0;
    local_db8[0x15] = 0;
    local_db8[0x16] = 0;
    local_db8[0x17] = 0;
    local_db8[0x18] = 0;
    local_db8[0x19] = 0;
    local_db8[0x1a] = 0;
    local_db8[0x1b] = 0;
    local_db8[0x1c] = 0;
    local_db8[0x1d] = 0;
    local_db8[0x1e] = 0;
    local_db8[0x1f] = 0;
    local_eb0 = 0x14078b6ee;
    iVar7 = func_0x0001414529a3(&local_e30,0,0,0x18);
    lVar3 = lVar3 + 1;
    puVar15 = (ulonglong *)local_ea8;
    if (iVar7 != 0) {
      local_e88 = &local_e38;
      plVar17 = &local_eb0;
      local_eb8 = 0x14078b717;
      local_eb0 = lVar3;
      iVar7 = func_0x000141501904(local_e30,0x800c,0,0);
      if (iVar7 != 0) {
        local_eb8 = 0x14078b734;
        lVar9 = func_0x000141ad8c70(local_e40,lVar2,(int)lVar3 - (int)lVar2,0);
        lVar3 = local_eb0;
        uVar12 = local_e38;
        puVar16 = local_ea8;
        if ((int)lVar9 != 0) {
          local_e88 = (undefined8 *)((ulonglong)local_e88 & 0xffffffff00000000);
          local_eb8 = 0x14078b75a;
          local_eb0 = lVar9;
          iVar7 = func_0x000141a2406d(local_e38,2,local_db8,local_e28);
          uVar12 = local_e40;
          puVar16 = (uint *)&local_eb0;
          if ((iVar7 != 0) && (puVar16 = (uint *)&local_eb0, local_e28[0] == 0x20)) {
            pbVar19 = local_db8;
            do {
              bVar1 = *pbVar19;
              uVar4 = uVar18 * 2;
              pbVar19 = pbVar19 + 1;
              uVar18 = uVar18 + 1;
              *(undefined1 *)((longlong)&local_e08 + (ulonglong)uVar4) =
                   (&DAT_140f8cec0)[bVar1 >> 4];
              *(undefined1 *)((longlong)&local_e08 + (ulonglong)(uVar4 + 1)) =
                   (&DAT_140f8cec0)[bVar1 & 0xf];
            } while (uVar18 < 0x20);
            local_dc8 = 0;
            local_ec0 = 0x14078b7c4;
            local_eb8 = lVar2;
            func_0x00014146f328(local_e40);
            local_ec8[0] = 0x4078b7d1;
            local_ec8[1] = 1;
            local_ec0 = unaff_RSI + 1;
            func_0x00014181deae(local_e40,0);
            local_ec8[0] = 0x4078b7e2;
            local_ec8[1] = 1;
            FUN_1407b4700(local_db8 + 0x20,0,0x105);
            local_ec8[0] = 0x104;
            local_ec8[1] = 0;
            lStack_ed0 = 0x14078b7f1;
            iVar7 = func_0x000141584516(0x104,local_db8 + 0x20);
            puVar15 = (ulonglong *)local_ec8;
            if (iVar7 - 1U < 0x103) {
              lStack_ed0 = 0x14078b812;
              FUN_1407b4700(local_c88,0,0x208);
              lStack_ed0 = 0x14078b82e;
              iVar7 = FUN_140789fd0(local_c88,0x208,0x140f8cf78);
              puVar15 = (ulonglong *)local_ec8;
              if (-1 < iVar7) {
                auStack_ef8[4] = 0x14078b84b;
                lStack_ed0 = unaff_RSI + 1;
                iVar7 = func_0x000141622d4d(local_c88);
                local_ea0[0] = 0;
                local_ea8[0] = 0x80;
                local_eb0 = CONCAT44(local_eb0._4_4_,4);
                puVar15 = auStack_ef8 + 4;
                puVar13 = auStack_ef8 + 4;
                auStack_ef8[4] = lVar3;
                auStack_ef8[3] = 0x14078b881;
                uVar10 = func_0x000141973fb8(local_c88,4,7);
                if (uVar10 != 0xffffffffffffffff) {
                  local_e28[1] = 0;
                  uVar21 = 0;
                  if (iVar7 == -1) {
                    puVar13 = auStack_ef8 + 3;
                    auStack_ef8[3] = (ulonglong)(iVar7 == -1);
                    uVar8 = func_0x000141adf83e(0x140f8cf90);
                    local_ec0 = 0;
                    uVar12 = 0x140f8cf90;
                    piVar11 = (int *)func_0x0001416b849a(uVar10,0x140f8cf90,uVar8,local_e28 + 1);
                    if ((bool)uVar21) {
                      *(char *)((longlong)piVar11 * 2) =
                           *(char *)((longlong)piVar11 * 2) + (char)piVar11;
                    /* WARNING: Bad instruction - Truncating control flow here */
                      halt_baddata();
                    }
                    pbVar19 = (byte *)((longlong)piVar11 + -0x73);
                    bVar1 = (byte)uVar10 & 7;
                    *pbVar19 = *pbVar19 >> bVar1 | *pbVar19 << 8 - bVar1;
                    uVar18 = (int)piVar11 + *piVar11;
                    cVar6 = (char)uVar18;
                    *(char *)(uVar10 - 0x48) = *(char *)(uVar10 - 0x48) + cVar6;
                    pcVar5 = (char *)((ulonglong)uVar18 * 2);
                    *pcVar5 = *pcVar5 + cVar6;
                    bVar20 = (int)piVar11 == 0;
                    uVar10 = (ulonglong)piVar11 & 0xffffffff;
                  }
                  else {
                    uVar12 = 0;
                    auStack_ef8[3] = 0x14078b8d3;
                    FUN_1407b4700(local_a78,0,0x400);
                    bVar20 = param_1 == 0;
                  }
                  puVar14 = (undefined1 *)puVar13;
                  if (!bVar20) {
                    *(undefined8 *)((longlong)puVar13 + 0x38) = 0;
                    *(undefined8 *)((longlong)puVar13 + 0x30) = 0;
                    *(undefined4 *)((longlong)puVar13 + 0x28) = 0x400;
                    uVar12 = 0;
                    *(undefined1 **)((longlong)puVar13 + 0x20) = local_a78;
                    puVar14 = (undefined1 *)((longlong)puVar13 + -8);
                    *(longlong *)((longlong)puVar13 + -8) = lVar3;
                    *(undefined8 *)((longlong)puVar13 + -0x10) = 0x14078b90c;
                    func_0x0001418c96d3(0xfde9,0,param_1,0xffffffff);
                  }
                  puVar15 = (ulonglong *)(puVar14 + -8);
                  *(undefined8 *)(puVar14 + -8) = uVar12;
                  *(undefined8 *)(puVar14 + -0x10) = 0x14078b916;
                  func_0x0001418cf842(&local_e20);
                  *(undefined8 *)(puVar14 + -0x10) = 0x14078b92a;
                  FUN_1407b4700(local_678,0,0x640);
                  lVar3 = param_2[1];
                  lVar2 = *param_2;
                  *(undefined8 **)(puVar14 + 0x58) = &local_e08;
                  *(longlong *)(puVar14 + 0x50) = lVar3 - lVar2;
                  *(undefined1 **)(puVar14 + 0x48) = local_a78;
                  *(uint *)(puVar14 + 0x40) = (uint)local_e12;
                  *(uint *)(puVar14 + 0x38) = (uint)local_e14;
                  *(uint *)(puVar14 + 0x30) = (uint)local_e16;
                  *(uint *)(puVar14 + 0x28) = (uint)local_e18;
                  *(uint *)(puVar14 + 0x20) = (uint)local_e1a;
                  *(uint *)(puVar14 + 0x18) = (uint)local_e1e;
                  *(undefined8 *)(puVar14 + -0x10) = 0x14078b99e;
                  iVar7 = FUN_140789fd0(local_678,0x640,0x140f8cfb0,local_e20);
                  if (0 < iVar7) {
                    *(undefined8 *)(puVar14 + 0x18) = 0;
                    *(undefined **)(puVar14 + -0x10) = &UNK_14078b9bd;
                    func_0x000141614301(uVar10,local_678,iVar7,local_e28 + 1);
                    /* WARNING: Bad instruction - Truncating control flow here */
                    halt_baddata();
                  }
                  *(undefined8 *)(puVar14 + -0x10) = 0x14078b9c6;
                  uVar21 = func_0x0001413f1716(uVar10);
                  *(undefined1 *)(ulonglong)local_e1e = uVar21;
                }
              }
            }
            goto LAB_14078b9d7;
          }
        }
        plVar17 = (longlong *)((longlong)puVar16 + -8);
        *(longlong *)((longlong)puVar16 + -8) = lVar2;
        *(undefined8 *)((longlong)puVar16 + -0x10) = 0x14078ba00;
        func_0x000141635be8(uVar12);
      }
      puVar15 = (ulonglong *)((longlong)plVar17 + -8);
      *(undefined8 *)((longlong)plVar17 + -8) = *(undefined8 *)((longlong)plVar17 + 0x78);
      *(undefined8 *)((longlong)plVar17 + -0x10) = 0x14078ba0d;
      func_0x0001419874ca(*(undefined8 *)((longlong)plVar17 + 0x78),0);
    }
  }
LAB_14078b9d7:
  *(undefined8 *)((longlong)puVar15 + -8) = 0x14078b9e6;
  return;
}


// ==== FUN_1407c1f44 @ 1407c1f44 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int FUN_1407c1f44(int param_1)

{
  longlong lVar1;
  longlong *plVar2;
  int iVar3;
  undefined4 *puVar4;
  longlong *plVar5;
  char *pcVar6;
  int iVar7;
  longlong *local_res10;
  longlong local_res18;
  undefined8 local_res20;
  
  iVar7 = 0;
  if (param_1 == 0) {
    return 0;
  }
  if (1 < param_1 - 1U) {
    puVar4 = (undefined4 *)FUN_1407c5618();
    *puVar4 = 0x16;
    FUN_1407b8bb4();
    return 0x16;
  }
  __acrt_initialize_multibyte();
  FUN_1407cc6fc(0,0x14115b120,0x104);
  _DAT_14115b288 = 0x14115b120;
  if ((_DAT_14115b2a8 == (char *)0x0) || (pcVar6 = _DAT_14115b2a8, *_DAT_14115b2a8 == '\0')) {
    pcVar6 = (char *)0x14115b120;
  }
  local_res18 = 0;
  local_res20 = 0;
  FUN_1407c1d24(pcVar6,0,0,&local_res18,&local_res20);
  lVar1 = local_res18;
  plVar5 = (longlong *)__acrt_allocate_buffer_for_argv(local_res18,local_res20,1);
  if (plVar5 == (longlong *)0x0) {
    puVar4 = (undefined4 *)FUN_1407c5618();
    iVar7 = 0xc;
    *puVar4 = 0xc;
  }
  else {
    FUN_1407c1d24(pcVar6,plVar5,plVar5 + lVar1,&local_res18,&local_res20);
    if (param_1 != 1) {
      local_res10 = (longlong *)0x0;
      iVar3 = thunk_FUN_1407cbfd4(plVar5,&local_res10);
      plVar2 = local_res10;
      if (iVar3 != 0) {
        FUN_1407c68b0(local_res10);
        local_res10 = (longlong *)0x0;
        FUN_1407c68b0(plVar5);
        return iVar3;
      }
      _DAT_14115b290 = 0;
      lVar1 = *local_res10;
      while (lVar1 != 0) {
        local_res10 = local_res10 + 1;
        _DAT_14115b290 = _DAT_14115b290 + 1;
        lVar1 = *local_res10;
      }
      local_res10 = (longlong *)0x0;
      _DAT_14115b298 = plVar2;
      FUN_1407c68b0(0);
      local_res10 = (longlong *)0x0;
      goto LAB_1407c20a9;
    }
    _DAT_14115b290 = (int)local_res18 + -1;
    _DAT_14115b298 = plVar5;
  }
  plVar5 = (longlong *)0x0;
LAB_1407c20a9:
  FUN_1407c68b0(plVar5);
  return iVar7;
}


// ==== FUN_1407a4a90 @ 1407a4a90 ====

void FUN_1407a4a90(void)

{
  FUN_1407a4940(0x140f92930);
  FUN_1407a4940(0x140f92970);
  return;
}


