"""
Generador de archivos Excel (.xlsx) sin librerías externas (solo la biblioteca estándar de Python).

Un .xlsx es un ZIP con archivos XML. Aquí se arma uno sencillo con:
  - encabezado en negrita y fondo de color, fila fija al desplazarse y filtros automáticos,
  - formatos de dinero (COP), fecha y número,
  - textos guardados como texto (Excel nunca los interpreta como fórmulas: no hay "inyección de fórmulas").
"""
import io
import re
import zipfile
from datetime import datetime
from xml.sax.saxutils import escape

# Estilos (índice dentro de <cellXfs> de styles.xml)
S_DEFAULT, S_HEADER, S_MONEY, S_DATE, S_INT, S_BOLD, S_BOLD_MONEY = 0, 1, 2, 3, 4, 5, 6
KIND_STYLE = {"text": S_DEFAULT, "money": S_MONEY, "date": S_DATE, "int": S_INT}

_ILLEGAL_XML = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f]")
_EPOCH = datetime(1899, 12, 30)


def _col_letter(index):
    """0 -> A, 25 -> Z, 26 -> AA."""
    letters = ""
    index += 1
    while index:
        index, rem = divmod(index - 1, 26)
        letters = chr(65 + rem) + letters
    return letters


def _text_cell(ref, value, style=S_DEFAULT):
    text = _ILLEGAL_XML.sub("", str(value))
    return f'<c r="{ref}" s="{style}" t="inlineStr"><is><t xml:space="preserve">{escape(text)}</t></is></c>'


def _number_cell(ref, value, style):
    return f'<c r="{ref}" s="{style}"><v>{value!r}</v></c>'


def _cell(ref, value, kind, bold=False):
    if value is None or value == "":
        return ""
    if kind == "date" and isinstance(value, datetime):
        # Se trabaja al segundo exacto y se suma medio milisegundo para que ningún redondeo muestre un minuto menos.
        delta = value.replace(tzinfo=None, microsecond=0) - _EPOCH
        serial = delta.days + delta.seconds / 86400 + 5e-9
        return _number_cell(ref, serial, S_DATE)
    if kind in ("money", "int"):
        try:
            number = float(value) if kind == "money" else int(value)
        except (TypeError, ValueError):
            return _text_cell(ref, value)
        style = (S_BOLD_MONEY if bold else S_MONEY) if kind == "money" else S_INT
        return _number_cell(ref, number, style)
    return _text_cell(ref, value, S_BOLD if bold else S_DEFAULT)


def _sheet_xml(columns, rows, total_row=None):
    """columns: [(encabezado, ancho, tipo)]; rows: lista de listas; total_row: lista opcional (fila final en negrita)."""
    last_col = _col_letter(len(columns) - 1)
    cols = "".join(
        f'<col min="{i + 1}" max="{i + 1}" width="{width}" customWidth="1"/>' for i, (_, width, _) in enumerate(columns)
    )
    xml_rows = []
    header = "".join(_text_cell(f"{_col_letter(i)}1", title, S_HEADER) for i, (title, _, _) in enumerate(columns))
    xml_rows.append(f'<row r="1" ht="22" customHeight="1">{header}</row>')
    for n, row in enumerate(rows, start=2):
        cells = "".join(_cell(f"{_col_letter(i)}{n}", value, columns[i][2]) for i, value in enumerate(row))
        xml_rows.append(f'<row r="{n}">{cells}</row>')
    data_end = len(rows) + 1
    if total_row:
        n = data_end + 2  # una fila en blanco de separación
        cells = "".join(_cell(f"{_col_letter(i)}{n}", value, columns[i][2], bold=True) for i, value in enumerate(total_row))
        xml_rows.append(f'<row r="{n}">{cells}</row>')
    autofilter = f'<autoFilter ref="A1:{last_col}{max(data_end, 1)}"/>' if rows else ""
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetViews><sheetView workbookViewId="0">'
        '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
        '</sheetView></sheetViews>'
        f"<cols>{cols}</cols>"
        f'<sheetData>{"".join(xml_rows)}</sheetData>'
        f"{autofilter}"
        "</worksheet>"
    )


_STYLES_XML = (
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<numFmts count="2">'
    '<numFmt numFmtId="164" formatCode="&quot;$&quot;\\ #,##0"/>'
    '<numFmt numFmtId="165" formatCode="yyyy\\-mm\\-dd\\ hh:mm"/>'
    "</numFmts>"
    '<fonts count="3">'
    '<font><sz val="11"/><name val="Calibri"/></font>'
    '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>'
    '<font><b/><sz val="11"/><name val="Calibri"/></font>'
    "</fonts>"
    '<fills count="3">'
    '<fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill>'
    '<fill><patternFill patternType="solid"><fgColor rgb="FF0F766E"/><bgColor indexed="64"/></patternFill></fill>'
    "</fills>"
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    '<cellXfs count="7">'
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
    '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1">'
    '<alignment vertical="center" wrapText="1"/></xf>'
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '<xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '<xf numFmtId="1" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
    '<xf numFmtId="164" fontId="2" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1"/>'
    "</cellXfs>"
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
    "</styleSheet>"
)


def _safe_sheet_name(name, used):
    name = re.sub(r"[\\/*?:\[\]]", " ", name).strip()[:31] or "Hoja"
    base, n = name, 2
    while name.lower() in used:
        name = f"{base[:28]} {n}"
        n += 1
    used.add(name.lower())
    return name


def build_xlsx(sheets):
    """
    sheets: lista de dicts {"name": str, "columns": [(encabezado, ancho, tipo)], "rows": [[...]], "total_row": [...] | None}
    tipo: 'text' | 'money' | 'int' | 'date'. Devuelve los bytes del archivo .xlsx.
    """
    used, names = set(), []
    for sheet in sheets:
        names.append(_safe_sheet_name(sheet["name"], used))

    content_types = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        + "".join(
            f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
            for i in range(1, len(sheets) + 1)
        )
        + "</Types>"
    )
    root_rels = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        "</Relationships>"
    )
    workbook = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
        + "".join(f'<sheet name="{escape(n, {chr(34): "&quot;"})}" sheetId="{i}" r:id="rId{i}"/>' for i, n in enumerate(names, 1))
        + "</sheets></workbook>"
    )
    workbook_rels = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        + "".join(
            f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>'
            for i in range(1, len(sheets) + 1)
        )
        + f'<Relationship Id="rId{len(sheets) + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        "</Relationships>"
    )

    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", content_types)
        z.writestr("_rels/.rels", root_rels)
        z.writestr("xl/workbook.xml", workbook)
        z.writestr("xl/_rels/workbook.xml.rels", workbook_rels)
        z.writestr("xl/styles.xml", _STYLES_XML)
        for i, sheet in enumerate(sheets, 1):
            z.writestr(f"xl/worksheets/sheet{i}.xml", _sheet_xml(sheet["columns"], sheet["rows"], sheet.get("total_row")))
    return buffer.getvalue()


# ---------------------------------------------------------------------------------------------
# Reporte de ventas
# ---------------------------------------------------------------------------------------------

DELIVERY_LABELS = {"pickup": "Recoger en bodega", "ship": "Envío a domicilio", "service": "Servicio en sitio"}


def seller_of(s):
    """Quién vendió o atendió la venta: siempre se muestra un valor."""
    attended = str(s.get("attended_by") or "").strip()
    if attended:
        return attended
    advisor = str(s.get("advisor") or "").strip()
    if advisor and s.get("advisor_role") != "Autoservicio":
        return advisor
    return "Pendiente de atender" if s.get("status") == "Pendiente" else "Sin asesor registrado"


def sales_report(sales):
    """
    sales: lista de dicts (uno por venta) con las claves:
      folio, date (datetime sin zona), customer, doc, phone, advisor, advisor_role, status, payment,
      delivery_method, city, address, notes, subtotal, tax, total, items=[{sku, name, qty, price}]
    Devuelve los bytes del .xlsx con dos hojas: «Ventas» (una fila por venta) y «Detalle» (una fila por producto).
    """
    sale_columns = [
        ("Folio", 12, "text"), ("Fecha", 17, "date"), ("Cliente", 28, "text"), ("Documento", 15, "text"),
        ("Teléfono", 15, "text"), ("Asesor de ventas", 26, "text"), ("Origen / rol del asesor", 22, "text"),
        ("Vendió / atendió", 24, "text"),
        ("Estado", 12, "text"), ("Forma de pago", 24, "text"), ("Entrega", 20, "text"), ("Ciudad", 16, "text"),
        ("Dirección", 30, "text"), ("Notas", 30, "text"), ("Productos", 48, "text"),
        ("Unidades", 10, "int"), ("Subtotal", 16, "money"), ("IVA (19 %)", 16, "money"), ("Total", 16, "money"),
    ]
    detail_columns = [
        ("Folio", 12, "text"), ("Fecha", 17, "date"), ("Cliente", 28, "text"), ("Estado", 12, "text"), ("Vendió / atendió", 24, "text"),
        ("Código", 14, "text"), ("Producto o servicio", 44, "text"), ("Cantidad", 10, "int"),
        ("Precio unitario", 16, "money"), ("Subtotal de la línea", 18, "money"),
    ]
    sale_rows, detail_rows = [], []
    valid_total = valid_subtotal = valid_tax = 0.0
    valid_count = valid_units = 0
    for s in sales:
        items = s.get("items", [])
        units = sum(i["qty"] for i in items)
        summary = "; ".join(f'{i["qty"]} × {i["name"]}' for i in items)
        sale_rows.append([
            s["folio"], s["date"], s["customer"], s["doc"], s["phone"], s["advisor"], s["advisor_role"],
            seller_of(s), s["status"], s["payment"], DELIVERY_LABELS.get(s["delivery_method"], ""), s["city"], s["address"],
            s["notes"], summary, units, s["subtotal"], s["tax"], s["total"],
        ])
        for i in items:
            detail_rows.append([
                s["folio"], s["date"], s["customer"], s["status"], seller_of(s), i["sku"], i["name"], i["qty"], i["price"],
                float(i["price"]) * i["qty"],
            ])
        if s["status"] != "Anulada":
            valid_count += 1
            valid_units += units
            valid_subtotal += float(s["subtotal"])
            valid_tax += float(s["tax"])
            valid_total += float(s["total"])

    total_row = [
        f"TOTAL ({valid_count} ventas, sin anuladas)", None, None, None, None, None, None, None, None, None, None,
        None, None, None, None, valid_units, valid_subtotal, valid_tax, valid_total,
    ]
    return build_xlsx([
        {"name": "Ventas", "columns": sale_columns, "rows": sale_rows, "total_row": total_row},
        {"name": "Detalle", "columns": detail_columns, "rows": detail_rows},
    ])
