from __future__ import annotations

from pathlib import Path


GROUP_SIZE = 34


def parse_groups(lines: list[str]) -> list[list[str]]:
    groups: list[list[str]] = []
    for i in range(0, len(lines), GROUP_SIZE):
        chunk = lines[i : i + GROUP_SIZE]
        if len(chunk) == GROUP_SIZE:
            groups.append(chunk)
    return groups


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    src = root / "cpu31-test.sim" / "sim_1" / "behav" / "_246tb_ex9_result.txt"
    dst = root / "verify" / "normalized_frontsim_result.txt"

    raw_lines = src.read_text(encoding="ascii").splitlines()
    groups = parse_groups(raw_lines)

    out: list[str] = []
    seen_states = set()
    for group in groups[2:]:
        pc_text = group[0].split(":")[1].strip()
        instr_text = group[1].split(":")[1].strip()
        pc = int(pc_text, 16)
        pc_norm = (pc - 8) & 0xFFFFFFFF

        regs = []
        for line in group[2:]:
            _, value = line.split(":")
            regs.append(value.strip())

        state = (pc_norm, instr_text, tuple(regs))
        if state in seen_states:
            break
        seen_states.add(state)

        out.append(f"pc: {pc_norm:08x}")
        out.append(f"instr: {instr_text}")
        for idx, value in enumerate(regs):
            out.append(f"regfile{idx}: {value}")

    dst.write_text("\n".join(out) + "\n", encoding="ascii")
    print(f"NORMALIZED={dst}")
    print(f"LINES={len(out)}")


if __name__ == "__main__":
    main()
