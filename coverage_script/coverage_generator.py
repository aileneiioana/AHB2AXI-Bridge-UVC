
import pandas as pd
import re

def generate_all_covergroups(xlsx_path, output_path, sheet_name="Covergroups"):
    df = pd.read_excel(xlsx_path, sheet_name=sheet_name)
    df = df[["Scope", "Cover group", "Sample ", "Item name", "Signal", "Values", "Ignores", "Illegals"]]
    df.columns = ["scope", "covergroup", "sample", "item", "signal", "values", "ignores", "illegals"]
    df.ffill(inplace=True)
    grouped = df.groupby(["scope", "covergroup", "sample"])

    sv_output = ""

    def format_coverpoint(item, signal):
        return f"  {item:<40}: coverpoint {signal};"

    def generate_named_toggle(item, signal):
        return (
            f"  {item} : coverpoint {signal} {{\n"
            f"    bins zeroone = (0 => 1);\n"
            f"    bins onezero = (1 => 0);\n"
            f"  }}")

    def format_cross(item, signal, ignores, illegals):
        expr = signal.replace("cross", "").strip()
        ignore_lines = []
        illegal_lines = []

        if isinstance(ignores, str) and "binsof" in ignores and "intersect" in ignores:
            for idx, line in enumerate(ignores.splitlines()):
                if "binsof" in line and "intersect" in line:
                    ignore_lines.append(f"    ignore_bins {item}_ig{idx} = {line.strip().rstrip(';')};")

        if isinstance(illegals, str) and "binsof" in illegals:
            for idx, line in enumerate(illegals.splitlines()):
                if "binsof" in line:
                    illegal_lines.append(f"    illegal_bins {item}_il{idx} = {line.strip().rstrip(';')};")

        if ignore_lines or illegal_lines:
            return f"  {item:<40}: cross {expr} {{\n" + "\n".join(ignore_lines + illegal_lines) + "\n  }"
        else:
            return f"  {item:<40}: cross {expr};"

    for (scope, cg_name, sample), group in grouped:
        if "with function" in sample:
            sample_clean = sample.replace("with function", "").strip()
            fn_name = sample_clean.split("(")[0].strip()
            sv_output += f"// Scope: {scope}\n"
            sv_output += f"covergroup {cg_name} with function {sample_clean};\n"
            for _, row in group.iterrows():
                if "[pos]" in row["signal"]:
                    sv_output += generate_named_toggle(row["item"], row["signal"]) + "\n"
            sv_output += "endgroup\n\n"
            sv_output += f"function void {fn_name}(bit[DW-1:0] data);\n"
            sv_output += f"  for(int i = 0; i < DW; i++) begin\n"
            sv_output += f"    {cg_name}.sample(data, i);\n"
            sv_output += f"  end\nendfunction\n\n"
        else:
            sv_output += f"// Scope: {scope}\n"
            sv_output += f"covergroup {cg_name} @{sample};\n"
            for _, row in group.iterrows():
                item = row["item"]
                signal = row["signal"]
                ignores = row["ignores"]
                illegals = row["illegals"]
                values = str(row["values"]).strip()

                if "cross" in str(signal).lower():
                    sv_output += format_cross(item, signal, ignores, illegals) + "\n"
                elif "=" in values and ";" in values:
                    sv_output += f"  {item:<40}: coverpoint {signal} {{\n"
                    for line in values.split(";"):
                        match = re.match(r"\s*(\w+)\s*=\s*({[^}]+}|[^;]+)", line.strip())
                        if match:
                            name, val = match.groups()
                            sv_output += f"    bins {name.strip()} = {val.strip()};\n"
                    sv_output += "  }\n"
                else:
                    sv_output += format_coverpoint(item, signal) + "\n"
            sv_output += "endgroup\n\n"

    with open(output_path, "w") as f:
        f.write(sv_output)

if __name__ == "__main__":
    generate_all_covergroups("AHB2AXI_Metric_plan.xlsx", "covergroups.sv")
