import os
import re

files_to_process = [
    'lib/features/hoteles/presentation/screens/hotel_list_screen.dart',
    'lib/features/settings/presentation/screens/sede_list_screen.dart',
    'lib/features/settings/presentation/screens/payment_method_list_screen.dart',
    'lib/features/pagos_realizados/presentation/screens/pago_realizado_list_screen.dart',
    'lib/features/faq/presentation/screens/faq_list_screen.dart',
    'lib/features/politica_reserva/presentation/screens/politica_reserva_list_screen.dart',
    'lib/features/agentes/presentation/screens/agente_list_screen.dart',
    'lib/features/info_empresa/presentation/screens/info_empresa_list_screen.dart',
    'lib/features/reservas/presentation/screens/reserva_list_screen.dart',
    'lib/features/cotizaciones/presentation/screens/cotizaciones_list_screen.dart',
    'lib/features/tour/presentation/screens/tour_list_screen.dart',
    'lib/features/service/presentation/screens/service_list_screen.dart',
    'lib/features/catalogue/presentation/screens/catalogue_list_screen.dart',
    'lib/features/clientes/presentation/screens/cliente_list_screen.dart',
    'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
]

for filepath in files_to_process:
    if not os.path.exists(filepath):
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove import of AdminShell
    content = re.sub(r"import\s+['\"].*?/layout/admin_shell\.dart['\"];\n", "", content)
    
    start_idx = content.find('return AdminShell(')
    if start_idx == -1: continue
        
    child_idx = content.find('child:', start_idx)
    if child_idx == -1: continue
        
    widget_match = re.search(r"child:\s*([A-Za-z0-9_]+)\(", content[start_idx:])
    if not widget_match: continue
    
    widget_name = widget_match.group(1)
    actual_widget_start = start_idx + widget_match.start(1)
    
    new_content = content[:start_idx] + 'return ' + content[actual_widget_start:]
    
    # Remove the trailing `);` that belonged to AdminShell.
    # Usually it's `    );\n  }\n}` or similar at the end of the `build` method.
    # Let's find the last occurrence of `);\n  }` and replace it with `;\n  }`
    
    # Or just find the matching parenthesis using a stack
    open_brackets = 0
    in_string = False
    escape = False
    
    for i in range(start_idx, len(new_content)):
        char = new_content[i]
        if char == '\\':
            escape = not escape
            continue
        if not escape and (char == "'" or char == '"'):
            # This is too simplistic for strings with quotes, but Dart doesn't have complex string interpolation here usually.
            pass
        escape = False
        
        if char == '(':
            open_brackets += 1
        elif char == ')':
            open_brackets -= 1
            if open_brackets == 0: # This is the closing bracket of the child widget
                # The next non-whitespace characters should be `);` for the AdminShell
                remainder = new_content[i+1:]
                match = re.match(r"\s*(\)?\s*;)", remainder)
                if match:
                    # Replace `);` with `;`
                    new_content = new_content[:i+1] + remainder[match.end(1):]
                    # Wait, if we replace `);` with ``, then what closes the return?
                    # The `)` at `new_content[i]` is the end of the widget.
                    # We need a `;` after it.
                    new_content = new_content[:i+1] + ';' + remainder[match.end(1):]
                break

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Processed {filepath}")
