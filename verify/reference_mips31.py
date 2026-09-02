from __future__ import annotations

from pathlib import Path


TEXT_BASE = 0x00400000
DATA_BASE = 0x10010000


def u32(value: int) -> int:
    return value & 0xFFFFFFFF


def s32(value: int) -> int:
    value &= 0xFFFFFFFF
    return value if value < 0x80000000 else value - 0x100000000


def load_imem(path: Path) -> list[int]:
    words = []
    for line in path.read_text(encoding="ascii").splitlines():
        text = line.strip()
        if not text:
            continue
        words.append(int(text, 2))
    return words


def run_program(imem_words: list[int], max_steps: int = 5000) -> list[str]:
    regs = [0] * 32
    dmem: dict[int, int] = {}
    pc = TEXT_BASE
    seen_states = set()
    out: list[str] = []

    for _ in range(max_steps):
        idx = (pc - TEXT_BASE) >> 2
        instr = imem_words[idx] if 0 <= idx < len(imem_words) else 0

        opcode = (instr >> 26) & 0x3F
        rs = (instr >> 21) & 0x1F
        rt = (instr >> 16) & 0x1F
        rd = (instr >> 11) & 0x1F
        shamt = (instr >> 6) & 0x1F
        funct = instr & 0x3F
        imm16 = instr & 0xFFFF
        imm26 = instr & 0x03FFFFFF

        sign_ext_imm = imm16 if imm16 < 0x8000 else imm16 - 0x10000
        zero_ext_imm = imm16
        pc_plus4 = u32(pc + 4)
        branch_target = u32(pc_plus4 + (sign_ext_imm << 2))
        jump_target = u32((pc_plus4 & 0xF0000000) | (imm26 << 2))

        rs_val = regs[rs]
        rt_val = regs[rt]

        next_pc = pc_plus4
        write_reg = None
        write_val = 0

        def read_word(addr: int) -> int:
            if addr == DATA_BASE + 0x10:
                return 0
            if addr < DATA_BASE:
                return 0
            return dmem.get((addr - DATA_BASE) >> 2, 0)

        def write_word(addr: int, value: int) -> None:
            if addr < DATA_BASE or addr == DATA_BASE + 0x10:
                return
            dmem[(addr - DATA_BASE) >> 2] = u32(value)

        if opcode == 0x00:
            if funct in (0x20, 0x21):
                write_reg = rd
                write_val = u32(rs_val + rt_val)
            elif funct in (0x22, 0x23):
                write_reg = rd
                write_val = u32(rs_val - rt_val)
            elif funct == 0x24:
                write_reg = rd
                write_val = rs_val & rt_val
            elif funct == 0x25:
                write_reg = rd
                write_val = rs_val | rt_val
            elif funct == 0x26:
                write_reg = rd
                write_val = rs_val ^ rt_val
            elif funct == 0x27:
                write_reg = rd
                write_val = u32(~(rs_val | rt_val))
            elif funct == 0x2A:
                write_reg = rd
                write_val = 1 if s32(rs_val) < s32(rt_val) else 0
            elif funct == 0x2B:
                write_reg = rd
                write_val = 1 if rs_val < rt_val else 0
            elif funct == 0x00:
                write_reg = rd
                write_val = u32(rt_val << shamt)
            elif funct == 0x02:
                write_reg = rd
                write_val = rt_val >> shamt
            elif funct == 0x03:
                write_reg = rd
                write_val = u32(s32(rt_val) >> shamt)
            elif funct == 0x04:
                write_reg = rd
                write_val = u32(rt_val << (rs_val & 0x1F))
            elif funct == 0x06:
                write_reg = rd
                write_val = rt_val >> (rs_val & 0x1F)
            elif funct == 0x07:
                write_reg = rd
                write_val = u32(s32(rt_val) >> (rs_val & 0x1F))
            elif funct == 0x08:
                next_pc = rs_val
        elif opcode in (0x08, 0x09):
            write_reg = rt
            write_val = u32(rs_val + sign_ext_imm)
        elif opcode == 0x0C:
            write_reg = rt
            write_val = rs_val & zero_ext_imm
        elif opcode == 0x0D:
            write_reg = rt
            write_val = rs_val | zero_ext_imm
        elif opcode == 0x0E:
            write_reg = rt
            write_val = rs_val ^ zero_ext_imm
        elif opcode == 0x0F:
            write_reg = rt
            write_val = imm16 << 16
        elif opcode == 0x0A:
            write_reg = rt
            write_val = 1 if s32(rs_val) < sign_ext_imm else 0
        elif opcode == 0x0B:
            write_reg = rt
            write_val = 1 if rs_val < u32(sign_ext_imm) else 0
        elif opcode == 0x04:
            if rs_val == rt_val:
                next_pc = branch_target
        elif opcode == 0x05:
            if rs_val != rt_val:
                next_pc = branch_target
        elif opcode == 0x23:
            addr = u32(rs_val + sign_ext_imm)
            write_reg = rt
            write_val = read_word(addr)
        elif opcode == 0x2B:
            addr = u32(rs_val + sign_ext_imm)
            write_word(addr, rt_val)
        elif opcode == 0x02:
            next_pc = jump_target
        elif opcode == 0x03:
            write_reg = 31
            write_val = pc_plus4
            next_pc = jump_target

        if write_reg is not None and write_reg != 0:
            regs[write_reg] = u32(write_val)
        regs[0] = 0

        out.append(f"pc: {pc:08x}")
        out.append(f"instr: {instr:08x}")
        for i, value in enumerate(regs):
            out.append(f"regfile{i}: {value:08x}")

        state = (pc, instr, tuple(regs), dmem.get(0, 0), dmem.get(1, 0))
        if state in seen_states:
            # Drop the duplicated state that marks steady looping.
            del out[-34:]
            break
        seen_states.add(state)

        pc = u32(next_pc)

    return out


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    imem_path = root / "cpu31-test.srcs" / "sources_1" / "ip" / "imem" / "imem.mif"
    out_path = root / "verify" / "reference_result_simulate.txt"
    words = load_imem(imem_path)
    lines = run_program(words)
    out_path.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"REFERENCE={out_path}")
    print(f"LINES={len(lines)}")


if __name__ == "__main__":
    main()
