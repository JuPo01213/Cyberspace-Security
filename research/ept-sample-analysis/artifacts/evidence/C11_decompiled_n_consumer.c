
/* WARNING: Control flow encountered bad instruction data */
/* WARNING: Instruction at (ram,0x0001407a223f) overlaps instruction at (ram,0x0001407a223b)
    */
/* WARNING: Function: __security_check_cookie replaced with injection: security_check_cookie */
/* WARNING: Type propagation algorithm not settling */

ulonglong FUN_1407a1fa0(int param_1,longlong param_2,undefined4 *param_3)

{
  byte bVar1;
  longlong lVar2;
  longlong lVar3;
  short sVar4;
  uint uVar5;
  int iVar6;
  undefined4 uVar7;
  byte *pbVar8;
  undefined8 uVar9;
  char *pcVar10;
  undefined4 *puVar11;
  undefined2 *puVar12;
  undefined4 *puVar13;
  undefined1 **ppuVar14;
  ulonglong uVar15;
  wchar_t *pwVar16;
  undefined4 *puVar17;
  undefined1 *puVar18;
  undefined1 **ppuVar19;
  undefined1 *puVar20;
  ulonglong uVar21;
  undefined1 *puVar22;
  undefined1 *puVar23;
  uint uVar24;
  longlong lVar25;
  char cVar26;
  undefined1 *puStack_add;
  undefined1 local_ad5 [453];
  undefined4 local_910;
  undefined4 uStack_90c;
  undefined8 uStack_908;
  undefined8 local_900;
  undefined8 uStack_8f8;
  undefined8 local_8f0;
  undefined8 uStack_8e8;
  undefined8 local_8e0;
  longlong lStack_8d8;
  undefined1 local_8d0 [32];
  undefined4 local_8b0;
  undefined4 uStack_8ac;
  undefined4 uStack_8a8;
  undefined4 uStack_8a4;
  undefined1 *local_8a0;
  undefined1 *puStack_898;
  undefined1 *local_890;
  undefined1 auStack_888 [8];
  undefined8 local_880;
  ulonglong local_878;
  short local_870 [116];
  undefined1 local_788 [296];
  undefined1 local_660 [256];
  undefined1 local_560 [528];
  undefined1 local_350 [264];
  undefined1 auStack_248 [528];
  ulonglong local_38;
  
  local_38 = (ulonglong)auStack_888 ^ 0x2b992ddfa232;
  if (1 < (longlong)param_1) {
    lVar25 = 1;
    do {
      local_890 = (undefined1 *)0x1407a2000;
      pbVar8 = (byte *)FUN_1407be830(*(undefined8 *)(param_2 + lVar25 * 8),"--nsp-runtime-child");
      ppuVar14 = (undefined1 **)auStack_888;
      if ((int)pbVar8 == 0) goto LAB_1407a20fb;
      lVar25 = lVar25 + 1;
    } while (lVar25 < param_1);
  }
  local_890 = (undefined1 *)0x1407a2024;
  FUN_1407b4700(auStack_248,0,0x208);
  local_890 = (undefined1 *)0x1407a2038;
  func_0x0001414c9aeb(0,auStack_248,0x104);
  uVar5 = in(0xff);
  pbVar8 = (byte *)(ulonglong)uVar5;
  puStack_898 = (undefined1 *)&local_890;
  bVar1 = *pbVar8;
  *pbVar8 = *pbVar8 + (byte)uVar5;
  ppuVar14 = (undefined1 **)local_ad5;
  if (CARRY1(bVar1,(byte)uVar5) || *pbVar8 == 0) {
    puStack_add = (undefined1 *)0x1407a205a;
    local_890 = local_788;
    FUN_1407b4700(local_560,0,0x208);
    puStack_add = local_560;
    iVar6 = func_0x0001415c46c8(0x104);
    pbVar8 = (byte *)(ulonglong)(iVar6 - 1U);
    ppuVar14 = &puStack_add;
    if (iVar6 - 1U < 0x103) {
      FUN_1407b4700(local_870,0,0x208);
      puVar13 = (undefined4 *)0x0;
      puVar17 = puVar13;
      ppuVar19 = &puStack_add;
      do {
        *(undefined8 *)((longlong)ppuVar19 + -8) = 0x1407a2095;
        uVar5 = FUN_1407a1f00();
        puVar11 = (undefined4 *)(ulonglong)uVar5;
        *(undefined8 *)((longlong)ppuVar19 + -8) = 0x1407a209c;
        uVar7 = FUN_1407a1f00();
        *(undefined4 *)((longlong)ppuVar19 + 0x28) = uVar7;
        *(uint *)((longlong)ppuVar19 + 0x20) = uVar5;
        *(undefined8 *)((longlong)ppuVar19 + -8) = 0x1407a20c0;
        pbVar8 = (byte *)FUN_140789eb0(local_870,0x104,L"%sEPT_%08X_%08X.exe",local_560);
        ppuVar14 = ppuVar19;
        if ((int)pbVar8 < 0) break;
        *(longlong *)((longlong)ppuVar19 + -8) = param_2;
        *(undefined8 *)((longlong)ppuVar19 + -0x10) = 0x1407a20d8;
        iVar6 = func_0x000141677922(local_350,local_870,0);
        if (iVar6 != 0) {
          local_890 = (undefined1 *)0x0;
          local_880 = 0;
          local_878 = 7;
          lVar25 = -1;
          do {
            lVar25 = lVar25 + 1;
          } while (local_870[lVar25] != 0);
          *(undefined8 *)((longlong)ppuVar19 + -0x10) = 0x1407a215b;
          FUN_1407ace80(&local_890,local_870);
          ppuVar14 = &local_890;
          if (7 < local_878) {
            ppuVar14 = (undefined1 **)local_890;
          }
          *(undefined8 *)((longlong)ppuVar19 + 0x28) = 0;
          *(undefined4 *)((longlong)ppuVar19 + 0x20) = 0x80;
          *(undefined4 *)((longlong)ppuVar19 + 0x18) = 3;
          cVar26 = '\0';
          *(undefined8 *)((longlong)ppuVar19 + -0x10) = 0x1407a218e;
          uVar9 = func_0x00014166d369(ppuVar14,4,1);
          uVar15 = CONCAT71((int7)((ulonglong)uVar9 >> 8),(char)uVar9 + 'H' + cVar26);
          uVar21 = uVar15 & 0xffffffff;
          puVar18 = (undefined1 *)((longlong)ppuVar19 + -8);
          if (uVar15 == 0xffffffffffffffff) {
LAB_1407a2206:
            if (7 < local_878) {
              lVar25 = local_878 * 2;
              if (0xfff < lVar25 + 2U) {
                lVar2 = *(longlong *)(local_890 + -8);
                if ((undefined1 *)0x1f < local_890 + (-8 - lVar2)) {
                    /* WARNING: Subroutine does not return */
                  *(undefined **)(puVar18 + -8) = &UNK_1407a2586;
                  FUN_1407b8bd4(lVar2,lVar25 + 0x29);
                }
              }
              goto LAB_1407a2241;
            }
          }
          else {
            puVar18 = local_660;
            puVar11 = puVar13;
            do {
              *(undefined8 *)((longlong)ppuVar19 + -0x10) = 0x1407a21a7;
              uVar5 = FUN_1407a1f00();
              uVar24 = (uint)puVar11;
              uVar5 = (uVar5 ^ uVar24 ^ 0xa5a55a5a) >> (sbyte)((uVar24 & 3) << 3);
              *puVar18 = (char)uVar5;
              uVar24 = uVar24 + 1;
              puVar11 = (undefined4 *)(ulonglong)uVar24;
              puVar18 = puVar18 + 1;
              cVar26 = uVar24 == 0x100;
            } while (uVar24 < 0x100);
            *(undefined4 *)((longlong)ppuVar19 + 0x40) = 0;
            *(undefined8 *)((longlong)ppuVar19 + 0x18) = 0;
            puVar18 = (undefined1 *)((longlong)ppuVar19 + -0x10);
            *(ulonglong *)((longlong)ppuVar19 + -0x10) = (ulonglong)uVar5;
            *(undefined8 *)((longlong)ppuVar19 + -0x18) = 0x1407a21ed;
            func_0x00014117c32e(uVar21,local_660,0x100,(undefined1 *)((longlong)ppuVar19 + 0x40));
            *(undefined8 *)((longlong)ppuVar19 + -0x18) = 0x1407a21f5;
            uVar15 = uVar21;
            pcVar10 = (char *)func_0x0001416221de();
            if (uVar15 == 1 || cVar26 != '\0') {
              puVar11 = (undefined4 *)((ulonglong)local_660 & 0xffffffff);
              for (lVar25 = 0x100; puVar18 = (undefined1 *)((longlong)ppuVar19 + -0x10), lVar25 != 0
                  ; lVar25 = lVar25 + -1) {
                *(undefined1 *)puVar11 = 0;
                puVar11 = (undefined4 *)((longlong)puVar11 + 1);
              }
              goto LAB_1407a2206;
            }
            *pcVar10 = *pcVar10 + (char)pcVar10;
LAB_1407a2241:
            *(undefined8 *)(puVar18 + -8) = 0x1407a2246;
            thunk_FUN_1407c68b0();
          }
          *(undefined8 *)(puVar18 + -8) = 0x1407a224f;
          FUN_140799d20(&local_8b0);
          *(undefined8 *)(puVar18 + -8) = 0x1407a225a;
          uVar5 = func_0x0001418a6ef8(0x10);
          puVar20 = puVar18;
          if ((uVar5 >> 0xf & 1) == 0) {
            puVar20 = puVar18 + -8;
            *(ulonglong *)(puVar18 + -8) = uVar21;
            *(undefined8 *)(puVar18 + -0x10) = 0x1407a226d;
            sVar4 = func_0x00014117489d(0xa0);
            if (-1 < sVar4) {
              *(undefined **)(puVar18 + -0x10) = &UNK_1407a227e;
              func_0x00014186dc26(0xa1);
                    /* WARNING: Bad instruction - Truncating control flow here */
              halt_baddata();
            }
          }
          puVar18 = puStack_898;
          puVar12 = (undefined2 *)&local_8b0;
          if ((undefined1 *)0x7 < puStack_898) {
            puVar12 = (undefined2 *)
                      CONCAT44(uStack_8ac,CONCAT22(local_8b0._2_2_,(undefined2)local_8b0));
          }
          *(undefined8 *)(puVar20 + 0x20) = 0xc;
          puVar22 = local_8a0;
          *(undefined8 *)(puVar20 + -8) = 0x1407a22ba;
          lVar25 = FUN_1407aeba0(puVar12,puVar22,0,L"--shift-open");
          if (lVar25 == -1) {
            *(undefined8 *)(puVar20 + -8) = 0x1407a22d1;
            uVar9 = FUN_1407abfb0(local_8d0,&local_8b0);
            *(undefined8 *)(puVar20 + -8) = 0x1407a22dd;
            puVar11 = (undefined4 *)FUN_140799e30(&local_890,uVar9);
            if (&local_8b0 != puVar11) {
              if ((undefined1 *)0x7 < puStack_898) {
                uVar15 = (longlong)puStack_898 * 2 + 2;
                lVar2 = CONCAT44(uStack_8ac,CONCAT22(local_8b0._2_2_,(undefined2)local_8b0));
                lVar25 = lVar2;
                if (0xfff < uVar15) {
                  uVar15 = (longlong)puStack_898 * 2 + 0x29;
                  lVar25 = *(longlong *)(lVar2 + -8);
                  if (0x1f < (lVar2 - lVar25) - 8U) goto LAB_1407a2587;
                }
                *(undefined8 *)(puVar20 + -8) = 0x1407a2329;
                thunk_FUN_1407c68b0(lVar25,uVar15);
              }
              local_8b0._0_2_ = (undefined2)*puVar11;
              local_8b0._2_2_ = (undefined2)((uint)*puVar11 >> 0x10);
              uStack_8ac = puVar11[1];
              uStack_8a8 = puVar11[2];
              uStack_8a4 = puVar11[3];
              local_8a0 = *(undefined1 **)(puVar11 + 4);
              puStack_898 = *(undefined1 **)(puVar11 + 6);
              *(undefined8 *)(puVar11 + 4) = 0;
              *(undefined8 *)(puVar11 + 6) = 7;
              *(undefined2 *)puVar11 = 0;
            }
            puVar22 = local_8a0;
            puVar18 = puStack_898;
            if (7 < local_878) {
              if (0xfff < local_878 * 2 + 2) {
                uVar15 = local_878 * 2 + 0x29;
                lVar25 = *(longlong *)(local_890 + -8);
                if ((undefined1 *)0x1f < local_890 + (-8 - lVar25)) {
LAB_1407a2587:
                    /* WARNING: Subroutine does not return */
                  *(undefined **)(puVar20 + -8) = &UNK_1407a258c;
                  FUN_1407b8bd4(lVar25,uVar15);
                }
              }
              *(undefined8 *)(puVar20 + -8) = 0x1407a23a0;
              thunk_FUN_1407c68b0();
              puVar22 = local_8a0;
              puVar18 = puStack_898;
            }
          }
          puVar23 = (undefined1 *)0x0;
          if (puVar22 != (undefined1 *)0x0) {
            if (puVar18 == puVar22) {
              *(undefined8 *)(puVar20 + 0x20) = 1;
              *(undefined8 *)(puVar20 + -8) = 0x1407a2402;
              FUN_1407af5d0(&local_8b0,1,puVar20[0x40],&DAT_140f90234);
              puVar23 = local_8a0;
              puVar18 = puStack_898;
            }
            else {
              local_8a0 = puVar22 + 1;
              puVar12 = (undefined2 *)&local_8b0;
              if ((undefined1 *)0x7 < puVar18) {
                puVar12 = (undefined2 *)
                          CONCAT44(uStack_8ac,CONCAT22(local_8b0._2_2_,(undefined2)local_8b0));
              }
              puVar12[(longlong)puVar22] = 0x20;
              puVar12[(longlong)(puVar22 + 1)] = 0;
              puVar23 = local_8a0;
              puVar18 = puStack_898;
            }
          }
          if ((ulonglong)((longlong)puVar18 - (longlong)puVar23) < 0x13) {
            *(undefined8 *)(puVar20 + 0x20) = 0x13;
            pwVar16 = (wchar_t *)0x13;
            *(undefined8 *)(puVar20 + -8) = 0x1407a246c;
            FUN_1407af5d0(&local_8b0,0x13,puVar20[0x40],L"--nsp-runtime-child");
          }
          else {
            puVar11 = &local_8b0;
            if ((undefined1 *)0x7 < puVar18) {
              puVar11 = (undefined4 *)
                        CONCAT44(uStack_8ac,CONCAT22(local_8b0._2_2_,(undefined2)local_8b0));
            }
            pwVar16 = L"--nsp-runtime-child";
            local_8a0 = puVar23 + 0x13;
            *(undefined8 *)(puVar20 + -8) = 0x1407a2441;
            FUN_1407b48f0((undefined2 *)((longlong)puVar11 + (longlong)puVar23 * 2),
                          L"--nsp-runtime-child",0x26);
            *(undefined2 *)((longlong)puVar11 + (longlong)(puVar23 + 0x13) * 2) = 0;
          }
          *(undefined8 *)(puVar20 + 0x50) = 0;
          *(undefined8 *)(puVar20 + 0x58) = 0;
          *(undefined8 *)(puVar20 + 0x60) = 0;
          *(undefined8 *)(puVar20 + 0x68) = 0;
          *(undefined8 *)(puVar20 + 0x70) = 0;
          *(undefined8 *)(puVar20 + 0x78) = 0;
          uStack_90c = 0;
          uStack_908 = 0;
          local_900 = 0;
          uStack_8f8 = 0;
          local_8f0 = 0;
          uStack_8e8 = 0;
          local_8e0 = 0;
          lStack_8d8 = 0;
          *(undefined4 *)(puVar20 + 0x50) = 0x70;
          *(undefined4 *)(puVar20 + 0x54) = 0x40;
          *(short **)(puVar20 + 0x68) = local_870;
          if (local_8a0 != (undefined1 *)0x0) {
            puVar13 = &local_8b0;
            if ((undefined1 *)0x7 < puStack_898) {
              puVar13 = (undefined4 *)
                        CONCAT44(uStack_8ac,CONCAT22(local_8b0._2_2_,(undefined2)local_8b0));
            }
          }
          *(undefined4 **)(puVar20 + 0x70) = puVar13;
          _local_910 = CONCAT44(uStack_90c,1);
          *(wchar_t **)(puVar20 + -8) = pwVar16;
          *(undefined8 *)(puVar20 + -0x10) = 0x1407a24d8;
          iVar6 = FUN_140383c04(puVar20 + 0x50);
          if (iVar6 == 0) {
            *(undefined4 **)(puVar20 + -0x10) = puVar11;
            *(undefined8 *)(puVar20 + -0x18) = 0x1407a24e6;
            func_0x00014117d3c4(local_870);
            uVar15 = 0;
          }
          else {
            *(undefined4 *)(puVar20 + 0x3c) = 0;
            lVar25 = lStack_8d8;
            if (lStack_8d8 != 0) {
              *(undefined **)(puVar20 + -0x10) = &UNK_1407a2503;
              func_0x000141aff89e(lVar25,0xffffffff);
                    /* WARNING: Bad instruction - Truncating control flow here */
              halt_baddata();
            }
            *(undefined4 **)(puVar20 + -0x10) = puVar11;
            *(undefined8 *)(puVar20 + -0x18) = 0x1407a2527;
            FUN_140383cba(local_870);
            if (param_3 != (undefined4 *)0x0) {
              *param_3 = *(undefined4 *)(puVar20 + 0x34);
            }
            uVar15 = 1;
          }
          puVar18 = puVar20 + -0x10;
          if ((undefined1 *)0x7 < puStack_898) {
            lVar25 = (longlong)puStack_898 * 2;
            lVar2 = CONCAT44(uStack_8ac,CONCAT22(local_8b0._2_2_,(undefined2)local_8b0));
            if (0xfff < lVar25 + 2U) {
              lVar3 = *(longlong *)(lVar2 + -8);
              if (0x1f < (lVar2 - lVar3) - 8U) {
                    /* WARNING: Subroutine does not return */
                *(undefined **)(puVar20 + -0x18) = &UNK_1407a2580;
                FUN_1407b8bd4(lVar3,lVar25 + 0x29);
              }
            }
            *(undefined8 *)(puVar20 + -0x18) = 0x1407a2572;
            thunk_FUN_1407c68b0();
            puVar18 = puVar20 + -0x10;
          }
          goto LAB_1407a20fd;
        }
        *(undefined8 *)((longlong)ppuVar19 + -0x10) = 0x1407a20e1;
        pbVar8 = (byte *)func_0x00014160daaa();
        puVar18 = (undefined1 *)((longlong)ppuVar19 + -8);
        if ((int)pbVar8 != 0x50) {
          ppuVar14 = (undefined1 **)((longlong)ppuVar19 + -0x10);
          *(longlong *)((longlong)ppuVar19 + -0x10) = param_2;
          *(undefined8 *)((longlong)ppuVar19 + -0x18) = 0x1407a20ed;
          pbVar8 = (byte *)func_0x0001413fa341();
          puVar18 = (undefined1 *)((longlong)ppuVar19 + -0x10);
          if ((int)pbVar8 != 0xb7) break;
        }
        ppuVar14 = (undefined1 **)puVar18;
        uVar5 = (int)puVar17 + 1;
        puVar17 = (undefined4 *)(ulonglong)uVar5;
        ppuVar19 = ppuVar14;
      } while ((int)uVar5 < 8);
    }
  }
LAB_1407a20fb:
  uVar15 = (ulonglong)pbVar8 & 0xffffffffffffff00;
  puVar18 = (undefined1 *)ppuVar14;
LAB_1407a20fd:
  *(undefined8 *)(puVar18 + -8) = 0x1407a210c;
  return uVar15;
}

