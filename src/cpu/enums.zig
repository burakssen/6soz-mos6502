pub const AddressingMode = enum {
    imp, // Implied,
    acc, // Accumulator
    imm, // Immediate
    zp, // Zero Page
    zpx, // Zero Page, X
    zpy, // Zero Page, Y
    rel, // Relative
    abs, // Absolute
    abx, // Absolute, X
    aby, // Absolute, Y
    ind, // Indirect
    izx, // Indexed Indirect (X)
    izy, // Indirect Indexed (Y)
};

pub const Operation = enum {
    adc,
    @"and",
    asl,
    bcc,
    bcs,
    beq,
    bit,
    bmi,
    bne,
    bpl,
    brk,
    bvc,
    bvs,
    clc,
    cld,
    cli,
    clv,
    cmp,
    cpx,
    cpy,
    dec,
    dex,
    dey,
    eor,
    inc,
    inx,
    iny,
    jmp,
    jsr,
    lda,
    ldx,
    ldy,
    lsr,
    nop,
    ora,
    pha,
    php,
    pla,
    plp,
    rol,
    ror,
    rti,
    rts,
    sbc,
    sec,
    sed,
    sei,
    sta,
    stx,
    sty,
    tax,
    tay,
    tsx,
    txa,
    txs,
    tya,
};
