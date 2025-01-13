# File: config/initializers/phonelib.rb

# Require the phonelib gem if needed (usually it's already required via Gemfile).
require 'phonelib'

# You can set a default country if you like, e.g. US or GU (Guam is also +1).
Phonelib.default_country = 'US'

# Use strict_check if you want stricter matching of phone numbers.
Phonelib.strict_check = true

# (Optional) if you want to parse “special” short numbers, etc.:
# Phonelib.parse_special = true

# If you want to override phone data or add custom rules, you can do so here:
# Phonelib.override_phone_data = {...}
