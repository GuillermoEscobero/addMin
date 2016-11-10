.data

    ROK: .word 2, 3, 4, 5, 6, 2, 3, 4, 5, 6
    R0:  .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    V0:  .word 1, 2, 3, 4, 5, 1, 2, 3, 4, 5
    V1:  .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1


.text
    
    main:
      la $a0 R0
      la $a1 V0
      la $a2 V1
      li $a3 10
      
      jal addv_1
      
      jal seqv_1

      jal addv_1_test1



    addv_1:   bge $a3 $0 continue1
              li $a0 -1
              jr $ra

  continue1:  li $t0 0
              la $t1 R0
              la $t2 V0
              la $t3 V1

              li $t7 4
              li $t8 1

      for1:  bge $t0 $a3 end1

              lw $t4 ($t1)
              lw $t5 ($t2)
              lw $t6 ($t3)

              add $t4 $t5 $t6

              sw $t4 ($t1)

              add $t0 $t0 $t8
              add $t1 $t1 $t7 
              add $t2 $t2 $t7
              add $t3 $t3 $t7

              b for1

        end1: jr $ra


    seqv_1:   bge $a3 $0 continue2
              li $a0 -1
              jr $ra

  continue2:  li $t0 0
              la $t1 R0
              la $t2 V0
              la $t3 V1

              li $t7 4
              li $t8 1

        for2:  bge $a3 $0 end2

              #lw $t4 ($t1)
              lw $t5 ($t2)
              lw $t6 ($t3)

              bne $t5 $t6 else2

              li $t9 1
              sw $t9 ($t4)

              add $t0 $t0 $t8
              add $t1 $t1 $t7 
              add $t2 $t2 $t7
              add $t3 $t3 $t7

              b for2

        else2:
              sw $0 ($a0)

              b for2

        end2: jr $ra


addv_1_test1:
              la $a0 R0
              la $a1 V0
              la $a2 V1
              li $a3 10



addv_2_test2: # (TODO: procedure addv_2_test2)
              #
              # for (i=0; i<100; i++)
              #      addv_2 R0 V0 V1 10
              #

              jr $ra