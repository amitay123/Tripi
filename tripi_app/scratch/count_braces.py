
content = open('/Users/amitay/tripi/tripi_app/lib/screens/itinerary_screen.dart').read()
# Extract _buildActivityItem
start_idx = content.find('Widget _buildActivityItem')
end_idx = content.find('// Item 1: Helper for Category Icon')
method = content[start_idx:end_idx]

open_p = method.count('(')
close_p = method.count(')')
open_b = method.count('[')
close_b = method.count(']')
open_c = method.count('{')
close_c = method.count('}')

print(f"Parentheses: ({open_p}, {close_p})")
print(f"Brackets: [{open_b}, {close_b}]")
print(f"Curly: {{{open_c}, {close_c}}}")
