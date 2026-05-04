from html import escape
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
KMAP_DIR = ROOT / "docs" / "assets" / "kmaps"
README = ROOT / "README.md"

COLORS = [
    "#2563eb",
    "#dc2626",
    "#16a34a",
    "#9333ea",
    "#ea580c",
    "#0891b2",
    "#be123c",
    "#4f46e5",
    "#65a30d",
    "#c026d3",
]


def b(value):
    return 1 if value else 0


def bits_to_int(bits):
    value = 0
    for bit in bits:
        value = (value << 1) | bit
    return value


def bit_label(bits):
    return "".join(str(bit) for bit in bits)


def md_escape(text):
    return text.replace("|", "\\|")


def xml_escape(text):
    return escape(str(text), quote=True)


def gray_codes(n):
    if n == 1:
        return [(0,), (1,)]
    if n == 2:
        return [(0, 0), (0, 1), (1, 1), (1, 0)]
    raise ValueError("Only 1-bit and 2-bit Gray axes are supported")


def axis_vars(var_names):
    if len(var_names) == 2:
        return var_names[:1], var_names[1:]
    if len(var_names) == 3:
        return var_names[:1], var_names[1:]
    if len(var_names) == 4:
        return var_names[:2], var_names[2:]
    raise ValueError("K-maps support 2, 3, or 4 variables")


def assignments(var_names):
    count = len(var_names)
    rows = []
    for value in range(2**count):
        bits = tuple((value >> shift) & 1 for shift in range(count - 1, -1, -1))
        rows.append(dict(zip(var_names, bits)))
    return rows


def grid_assignments(var_names):
    row_vars, col_vars = axis_vars(var_names)
    row_codes = gray_codes(len(row_vars))
    col_codes = gray_codes(len(col_vars))
    grid = []
    for row_bits in row_codes:
        row = []
        for col_bits in col_codes:
            values = {}
            values.update(zip(row_vars, row_bits))
            values.update(zip(col_vars, col_bits))
            row.append(values)
        grid.append(row)
    return row_vars, col_vars, row_codes, col_codes, grid


def contiguous_runs(indexes, size):
    indexes = sorted(set(indexes))
    if not indexes:
        return []
    if indexes == list(range(size)):
        return [indexes]

    runs = []
    current = [indexes[0]]
    for idx in indexes[1:]:
        if idx == current[-1] + 1:
            current.append(idx)
        else:
            runs.append(current)
            current = [idx]
    runs.append(current)
    return runs


def term_cells(term, grid):
    cells = []
    for r, row in enumerate(grid):
        for c, values in enumerate(row):
            if all(values[name] == expected for name, expected in term["constraints"].items()):
                cells.append((r, c))
    return cells


def svg_kmap(module_id, output, var_names, func, terms, note):
    row_vars, col_vars, row_codes, col_codes, grid = grid_assignments(var_names)
    cell = 62
    label_w = 96
    label_h = 64
    legend_h = max(58, 22 * max(1, len(terms)))
    width = label_w + cell * len(col_codes) + 38
    height = label_h + cell * len(row_codes) + legend_h + 24
    x0 = label_w
    y0 = label_h

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-label="{xml_escape(module_id)} {xml_escape(output)} Karnaugh map">',
        "<style>",
        ".title{font:700 18px Arial,sans-serif;fill:#111827}",
        ".axis{font:600 12px Arial,sans-serif;fill:#374151}",
        ".label{font:600 13px Arial,sans-serif;fill:#111827}",
        ".cell{fill:#ffffff;stroke:#d1d5db;stroke-width:1}",
        ".one{fill:#f8fafc}",
        ".value{font:700 22px Arial,sans-serif;fill:#111827}",
        ".legend{font:12px Arial,sans-serif;fill:#111827}",
        ".note{font:11px Arial,sans-serif;fill:#4b5563}",
        "</style>",
        f'<rect x="0" y="0" width="{width}" height="{height}" fill="#ffffff"/>',
        f'<text x="16" y="26" class="title">{xml_escape(module_id)}: {xml_escape(output)}</text>',
        f'<text x="16" y="44" class="note">{xml_escape(note)}</text>',
        f'<text x="{x0 + (cell * len(col_codes)) / 2}" y="{y0 - 34}" text-anchor="middle" class="axis">{xml_escape(" ".join(col_vars))}</text>',
        f'<text x="18" y="{y0 + (cell * len(row_codes)) / 2}" class="axis">{xml_escape(" ".join(row_vars))}</text>',
    ]

    for c, bits in enumerate(col_codes):
        x = x0 + c * cell + cell / 2
        parts.append(f'<text x="{x}" y="{y0 - 10}" text-anchor="middle" class="label">{xml_escape(bit_label(bits))}</text>')
    for r, bits in enumerate(row_codes):
        y = y0 + r * cell + cell / 2 + 5
        parts.append(f'<text x="{x0 - 18}" y="{y}" text-anchor="end" class="label">{xml_escape(bit_label(bits))}</text>')

    values_grid = []
    for r, row in enumerate(grid):
        values_row = []
        for c, values in enumerate(row):
            out = b(func(values))
            values_row.append(out)
            cls = "cell one" if out else "cell"
            x = x0 + c * cell
            y = y0 + r * cell
            parts.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" class="{cls}"/>')
            parts.append(
                f'<text x="{x + cell / 2}" y="{y + cell / 2 + 8}" text-anchor="middle" class="value">{out}</text>'
            )
        values_grid.append(values_row)

    for index, term in enumerate(terms):
        color = COLORS[index % len(COLORS)]
        cells = term_cells(term, grid)
        rows = [r for r, _ in cells]
        cols = [c for _, c in cells]
        for row_run in contiguous_runs(rows, len(row_codes)):
            for col_run in contiguous_runs(cols, len(col_codes)):
                selected = {(r, c) for r in row_run for c in col_run}
                if not selected.issubset(set(cells)):
                    continue
                x = x0 + min(col_run) * cell + 4
                y = y0 + min(row_run) * cell + 4
                w = len(col_run) * cell - 8
                h = len(row_run) * cell - 8
                parts.append(
                    f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="9" fill="{color}" fill-opacity="0.14" stroke="{color}" stroke-width="3"/>'
                )

    legend_y = y0 + cell * len(row_codes) + 28
    parts.append(f'<text x="16" y="{legend_y}" class="axis">Groups</text>')
    for index, term in enumerate(terms):
        color = COLORS[index % len(COLORS)]
        y = legend_y + 20 + index * 20
        parts.append(f'<rect x="16" y="{y - 12}" width="14" height="14" rx="3" fill="{color}" fill-opacity="0.22" stroke="{color}" stroke-width="2"/>')
        parts.append(f'<text x="38" y="{y}" class="legend">{xml_escape(term["expr"])}</text>')

    parts.append("</svg>")
    return "\n".join(parts)


def truth_table_markdown(var_names, outputs):
    headers = var_names + [name for name, _, _ in outputs]
    rows = ["| " + " | ".join(headers) + " |", "| " + " | ".join(["---"] * len(headers)) + " |"]
    for values in assignments(var_names):
        row = [str(values[name]) for name in var_names]
        for _, func, _ in outputs:
            row.append(str(b(func(values))))
        rows.append("| " + " | ".join(row) + " |")
    return "\n".join(rows)


def write_svgs(module):
    paths = []
    for output_name, func, terms in module["outputs"]:
        svg = svg_kmap(module["id"], output_name, module["vars"], func, terms, module["note"])
        file_name = f'{module["slug"]}_{output_name.lower().replace(" ", "_").replace("/", "_")}.svg'
        path = KMAP_DIR / file_name
        path.write_text(svg, encoding="utf-8")
        paths.append((output_name, path.relative_to(ROOT).as_posix()))
    return paths


def module_section(module):
    svg_paths = write_svgs(module)
    lines = [
        f'<details>',
        f'<summary>{module["title"]}</summary>',
        "",
        module["description"],
        "",
        "**Truth table**",
        "",
        truth_table_markdown(module["vars"], module["outputs"]),
        "",
        "**Karnaugh maps**",
        "",
    ]
    for output_name, path in svg_paths:
        lines.append(f'![{module["title"]} {output_name} K-map]({path})')
        lines.append("")
    lines.append("</details>")
    return "\n".join(lines)


def term(expr, **constraints):
    return {"expr": expr, "constraints": constraints}


def v(name):
    return lambda values: values[name]


def not_v(name):
    return lambda values: not values[name]


def add3_value(values):
    value = bits_to_int([values["A3"], values["A2"], values["A1"], values["A0"]])
    if value <= 4:
        out = value
    elif value <= 9:
        out = value + 3
    else:
        out = 0
    return out


def bit_from(value_func, bit):
    return lambda values: (value_func(values) >> bit) & 1


MODULES = [
    {
        "id": "D-100.6",
        "slug": "d100_6_edge_detectors",
        "title": "D-100.6 Edge Detectors",
        "vars": ["button", "prev"],
        "note": "Rows/columns show current button and stored previous state.",
        "description": "The edge detector outputs are one-clock pulses derived from the current button value and the previous sampled value.",
        "outputs": [
            ("pos_edge", lambda x: x["button"] and not x["prev"], [term("button & ~prev", button=1, prev=0)]),
            ("neg_edge", lambda x: (not x["button"]) and x["prev"], [term("~button & prev", button=0, prev=1)]),
            ("any_edge", lambda x: x["button"] ^ x["prev"], [term("button & ~prev", button=1, prev=0), term("~button & prev", button=0, prev=1)]),
        ],
    },
    {
        "id": "D-100.7",
        "slug": "d100_7_sr_latch_control",
        "title": "D-100.7 SR Latch Control Logic",
        "vars": ["pos_SW1", "pos_SW2", "LED1"],
        "note": "LED1 is the current stored state; outputs are next/control logic.",
        "description": "This documents the Boolean logic around the D flip-flop in the SR latch task.",
        "outputs": [
            ("LED2_Ctrl", lambda x: x["pos_SW1"] or x["pos_SW2"], [term("pos_SW1", pos_SW1=1), term("pos_SW2", pos_SW2=1)]),
            ("LED1_next", lambda x: x["pos_SW2"] or ((not x["pos_SW1"]) and x["LED1"]), [term("pos_SW2", pos_SW2=1), term("~pos_SW1 & LED1", pos_SW1=0, LED1=1)]),
        ],
    },
    {
        "id": "D-100.8",
        "slug": "d100_8_seven_segment",
        "title": "D-100.8 Seven-Segment Decoder",
        "vars": ["D3", "D2", "D1", "D0"],
        "note": "Maps show segment ON logic before active-low inversion in code.",
        "description": "The Go Board display is active-low, so these maps show the logical condition for a segment to be lit. The Verilog outputs invert these expressions with `~(...)`.",
        "outputs": [
            ("A_on", lambda x: ((not x["D0"]) and x["D1"]) or ((not x["D0"]) and (not x["D2"])) or (x["D1"] and x["D2"]) or (x["D1"] and (not x["D3"])) or ((not x["D1"]) and (not x["D2"]) and x["D3"]) or ((not x["D0"]) and (not x["D1"]) and x["D3"]) or (x["D0"] and x["D2"] and (not x["D3"])), [
                term("~D0 & D1", D0=0, D1=1),
                term("~D0 & ~D2", D0=0, D2=0),
                term("D1 & D2", D1=1, D2=1),
                term("D1 & ~D3", D1=1, D3=0),
                term("~D1 & ~D2 & D3", D1=0, D2=0, D3=1),
                term("~D0 & ~D1 & D3", D0=0, D1=0, D3=1),
                term("D0 & D2 & ~D3", D0=1, D2=1, D3=0),
            ]),
            ("B_on", lambda x: ((not x["D2"]) and (not x["D3"])) or ((not x["D0"]) and (not x["D2"])) or (x["D0"] and x["D1"] and (not x["D3"])) or ((not x["D0"]) and (not x["D1"]) and (not x["D3"])) or (x["D0"] and (not x["D1"]) and x["D3"]), [
                term("~D2 & ~D3", D2=0, D3=0),
                term("~D0 & ~D2", D0=0, D2=0),
                term("D0 & D1 & ~D3", D0=1, D1=1, D3=0),
                term("~D0 & ~D1 & ~D3", D0=0, D1=0, D3=0),
                term("D0 & ~D1 & D3", D0=1, D1=0, D3=1),
            ]),
            ("C_on", lambda x: ((not x["D1"]) and (not x["D3"])) or ((not x["D1"]) and (not x["D2"])) or (x["D0"] and (not x["D3"])) or (x["D1"] and x["D2"] and (not x["D3"])) or (x["D0"] and (not x["D1"])) or (x["D3"] and (not x["D2"])), [
                term("~D1 & ~D3", D1=0, D3=0),
                term("~D1 & ~D2", D1=0, D2=0),
                term("D0 & ~D3", D0=1, D3=0),
                term("D1 & D2 & ~D3", D1=1, D2=1, D3=0),
                term("D0 & ~D1", D0=1, D1=0),
                term("D3 & ~D2", D3=1, D2=0),
            ]),
            ("D_on", lambda x: ((not x["D1"]) and x["D3"]) or (x["D1"] and (not x["D2"]) and (not x["D3"])) or ((not x["D0"]) and x["D1"] and (not x["D3"])) or ((not x["D0"]) and x["D1"] and x["D2"]) or (x["D0"] and (not x["D2"]) and x["D3"]) or ((not x["D0"]) and (not x["D1"]) and (not x["D2"])) or (x["D0"] and (not x["D1"]) and x["D2"] and (not x["D3"])), [
                term("~D1 & D3", D1=0, D3=1),
                term("D1 & ~D2 & ~D3", D1=1, D2=0, D3=0),
                term("~D0 & D1 & ~D3", D0=0, D1=1, D3=0),
                term("~D0 & D1 & D2", D0=0, D1=1, D2=1),
                term("D0 & ~D2 & D3", D0=1, D2=0, D3=1),
                term("~D0 & ~D1 & ~D2", D0=0, D1=0, D2=0),
                term("D0 & ~D1 & D2 & ~D3", D0=1, D1=0, D2=1, D3=0),
            ]),
            ("E_on", lambda x: ((not x["D0"]) and x["D1"]) or (x["D2"] and x["D3"]) or (x["D1"] and x["D3"]) or ((not x["D0"]) and (not x["D2"])), [
                term("~D0 & D1", D0=0, D1=1),
                term("D2 & D3", D2=1, D3=1),
                term("D1 & D3", D1=1, D3=1),
                term("~D0 & ~D2", D0=0, D2=0),
            ]),
            ("F_on", lambda x: ((not x["D0"]) and (not x["D1"])) or ((not x["D2"]) and x["D3"]) or (x["D1"] and x["D3"]) or ((not x["D0"]) and x["D2"]) or ((not x["D1"]) and x["D2"] and (not x["D3"])), [
                term("~D0 & ~D1", D0=0, D1=0),
                term("~D2 & D3", D2=0, D3=1),
                term("D1 & D3", D1=1, D3=1),
                term("~D0 & D2", D0=0, D2=1),
                term("~D1 & D2 & ~D3", D1=0, D2=1, D3=0),
            ]),
            ("G_on", lambda x: ((not x["D0"]) and x["D1"]) or ((not x["D2"]) and x["D3"]) or (x["D1"] and x["D3"]) or (x["D0"] and x["D3"]) or ((not x["D1"]) and x["D2"] and (not x["D3"])) or (x["D1"] and (not x["D2"])), [
                term("~D0 & D1", D0=0, D1=1),
                term("~D2 & D3", D2=0, D3=1),
                term("D1 & D3", D1=1, D3=1),
                term("D0 & D3", D0=1, D3=1),
                term("~D1 & D2 & ~D3", D1=0, D2=1, D3=0),
                term("D1 & ~D2", D1=1, D2=0),
            ]),
        ],
    },
    {
        "id": "D-100.9",
        "slug": "d100_9_counter_4_1",
        "title": "D-100.9 Counter 4 to 1",
        "vars": ["D2", "D1", "D0"],
        "note": "Maps show next-state equations for the stored counter bits.",
        "description": "The truth table includes all 3-bit states; invalid states are shown according to the written equations.",
        "outputs": [
            ("D2_next", lambda x: x["D0"] and (not x["D1"]) and (not x["D2"]), [term("D0 & ~D1 & ~D2", D0=1, D1=0, D2=0)]),
            ("D1_next", lambda x: (x["D0"] and x["D1"] and (not x["D2"])) or ((not x["D0"]) and (not x["D1"]) and x["D2"]), [term("D0 & D1 & ~D2", D0=1, D1=1, D2=0), term("~D0 & ~D1 & D2", D0=0, D1=0, D2=1)]),
            ("D0_next", lambda x: ((not x["D0"]) and x["D1"] and (not x["D2"])) or ((not x["D0"]) and (not x["D1"]) and x["D2"]), [term("~D0 & D1 & ~D2", D0=0, D1=1, D2=0), term("~D0 & ~D1 & D2", D0=0, D1=0, D2=1)]),
        ],
    },
    {
        "id": "D-100.10",
        "slug": "d100_10_counter_up_down",
        "title": "D-100.10 Counter Up/Down",
        "vars": ["D2", "D1", "D0", "X"],
        "note": "X=1 counts up, X=0 counts down.",
        "description": "These maps document the three next-state equations for the 1-to-4 up/down counter. The table includes all bit combinations; unused states are shown according to the written equations.",
        "outputs": [
            ("D2_next", lambda x: (x["D0"] and x["D1"] and (not x["D2"]) and x["X"]) or (x["D0"] and (not x["D1"]) and (not x["D2"]) and (not x["X"])), [term("D0 & D1 & ~D2 & X", D0=1, D1=1, D2=0, X=1), term("D0 & ~D1 & ~D2 & ~X", D0=1, D1=0, D2=0, X=0)]),
            ("D1_next", lambda x: (x["D0"] and x["D1"] and (not x["D2"]) and (not x["X"])) or ((not x["D0"]) and (not x["D1"]) and x["D2"] and (not x["X"])) or (x["D0"] and (not x["D1"]) and (not x["D2"]) and x["X"]) or ((not x["D0"]) and x["D1"] and (not x["D2"]) and x["X"]), [term("D0 & D1 & ~D2 & ~X", D0=1, D1=1, D2=0, X=0), term("~D0 & ~D1 & D2 & ~X", D0=0, D1=0, D2=1, X=0), term("D0 & ~D1 & ~D2 & X", D0=1, D1=0, D2=0, X=1), term("~D0 & D1 & ~D2 & X", D0=0, D1=1, D2=0, X=1)]),
            ("D0_next", lambda x: ((not x["D0"]) and (not x["D1"]) and x["D2"] and (not x["X"])) or ((not x["D0"]) and (not x["D1"]) and x["D2"] and x["X"]) or ((not x["D0"]) and x["D1"] and (not x["D2"]) and (not x["X"])) or ((not x["D0"]) and x["D1"] and (not x["D2"]) and x["X"]), [term("~D0 & ~D1 & D2 & ~X", D0=0, D1=0, D2=1, X=0), term("~D0 & ~D1 & D2 & X", D0=0, D1=0, D2=1, X=1), term("~D0 & D1 & ~D2 & ~X", D0=0, D1=1, D2=0, X=0), term("~D0 & D1 & ~D2 & X", D0=0, D1=1, D2=0, X=1)]),
        ],
    },
    {
        "id": "D-100.11",
        "slug": "d100_11_letter_counter",
        "title": "D-100.11 Letter Counter A-F",
        "vars": ["D2", "D1", "D0", "X"],
        "note": "D3 is fixed to 1; X=1 counts up, X=0 counts down.",
        "description": "These maps document the lower three next-state bits for the A-F up/down counter. The table includes all lower-bit combinations; states outside A-F are shown according to the written equations.",
        "outputs": [
            ("D2_next", lambda x: ((not x["D0"]) and x["D1"] and x["D2"]) or ((not x["D0"]) and x["D1"] and x["X"]) or (x["D0"] and x["D2"] and x["X"]) or ((not x["D1"]) and x["D2"] and (not x["X"])) or (x["D0"] and x["D1"] and (not x["D2"]) and (not x["X"])), [term("~D0 & D1 & D2", D0=0, D1=1, D2=1), term("~D0 & D1 & X", D0=0, D1=1, X=1), term("D0 & D2 & X", D0=1, D2=1, X=1), term("~D1 & D2 & ~X", D1=0, D2=1, X=0), term("D0 & D1 & ~D2 & ~X", D0=1, D1=1, D2=0, X=0)]),
            ("D1_next", lambda x: ((not x["D0"]) and x["D1"] and (not x["X"])) or (x["D0"] and x["D1"] and x["D2"]) or (x["D1"] and (not x["D2"]) and x["X"]) or (x["D0"] and x["D2"] and (not x["X"])) or ((not x["D0"]) and (not x["D1"]) and x["D2"] and x["X"]), [term("~D0 & D1 & ~X", D0=0, D1=1, X=0), term("D0 & D1 & D2", D0=1, D1=1, D2=1), term("D1 & ~D2 & X", D1=1, D2=0, X=1), term("D0 & D2 & ~X", D0=1, D2=1, X=0), term("~D0 & ~D1 & D2 & X", D0=0, D1=0, D2=1, X=1)]),
            ("D0_next", lambda x: ((not x["D0"]) and x["D1"]) or ((not x["D0"]) and x["D2"]), [term("~D0 & D1", D0=0, D1=1), term("~D0 & D2", D0=0, D2=1)]),
        ],
    },
    {
        "id": "D-100.12",
        "slug": "d100_12_add_3",
        "title": "D-100.12 add_3 Correction Block",
        "vars": ["A3", "A2", "A1", "A0"],
        "note": "For 1010-1111, the module default returns 0000.",
        "description": "`add_3` passes values 0-4 through unchanged and maps 5-9 to value+3 for the C-add-3 BCD converter.",
        "outputs": [
            ("S3", bit_from(add3_value, 3), [
                term("~A3 & A2 & A0", A3=0, A2=1, A0=1),
                term("~A3 & A2 & A1", A3=0, A2=1, A1=1),
                term("A3 & ~A2 & ~A1", A3=1, A2=0, A1=0),
            ]),
            ("S2", bit_from(add3_value, 2), [
                term("~A3 & A2 & ~A1 & ~A0", A3=0, A2=1, A1=0, A0=0),
                term("A3 & ~A2 & ~A1 & A0", A3=1, A2=0, A1=0, A0=1),
            ]),
            ("S1", bit_from(add3_value, 1), [
                term("~A3 & ~A2 & A1", A3=0, A2=0, A1=1),
                term("~A3 & A2 & A1 & A0", A3=0, A2=1, A1=1, A0=1),
                term("A3 & ~A2 & ~A1 & ~A0", A3=1, A2=0, A1=0, A0=0),
            ]),
            ("S0", bit_from(add3_value, 0), [
                term("~A3 & ~A2 & A0", A3=0, A2=0, A0=1),
                term("~A3 & A2 & A1 & ~A0", A3=0, A2=1, A1=1, A0=0),
                term("A3 & ~A2 & ~A1 & ~A0", A3=1, A2=0, A1=0, A0=0),
            ]),
        ],
    },
    {
        "id": "D-100.17",
        "slug": "d100_17_dice_decoder",
        "title": "D-100.17 Dice LED Decoder",
        "vars": ["D2", "D1", "D0"],
        "note": "L0-L6 are physical LED positions on the dice PCB.",
        "description": "The decoder maps binary values 001-110 to the seven LED positions of a dice face. The unused 000 and 111 rows are included so the table fully matches the written Boolean equations.",
        "outputs": [
            ("L0_PMOD1", lambda x: x["D2"], [term("D2", D2=1)]),
            ("L1_PMOD2", lambda x: x["D1"] and x["D2"], [term("D1 & D2", D1=1, D2=1)]),
            ("L2_PMOD3", lambda x: x["D1"] or x["D2"], [term("D1", D1=1), term("D2", D2=1)]),
            ("L3_PMOD4", lambda x: x["D0"], [term("D0", D0=1)]),
            ("L4_PMOD7", lambda x: x["D1"] or x["D2"], [term("D1", D1=1), term("D2", D2=1)]),
            ("L5_PMOD8", lambda x: x["D1"] and x["D2"], [term("D1 & D2", D1=1, D2=1)]),
            ("L6_PMOD9", lambda x: x["D2"], [term("D2", D2=1)]),
        ],
    },
]


def build_reference():
    KMAP_DIR.mkdir(parents=True, exist_ok=True)
    sections = [
        "## Truth Tables And Karnaugh Maps",
        "",
        "The tables below document the Boolean-expression modules in the project. Karnaugh maps use Gray-code ordering on both axes, and the colored boxes show the product terms used in the Verilog equations. The SVG files are generated into `docs/assets/kmaps/` and embedded here so they render cleanly on GitHub.",
        "",
    ]
    for module in MODULES:
        sections.append(module_section(module))
        sections.append("")
    return "\n".join(sections).rstrip() + "\n"


def update_readme(reference):
    start = "<!-- LOGIC_DOCS_START -->"
    end = "<!-- LOGIC_DOCS_END -->"
    block = f"{start}\n{reference}{end}"
    text = README.read_text(encoding="utf-8")
    if start in text and end in text:
        before, rest = text.split(start, 1)
        _, after = rest.split(end, 1)
        text = before + block + after
    else:
        marker = "\n---\n\n## Implemented Tasks"
        text = text.replace(marker, f"\n---\n\n{block}\n\n---\n\n## Implemented Tasks", 1)
    README.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    update_readme(build_reference())
