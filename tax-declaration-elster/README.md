# Tax Declaration Elster - Automated Form Filling

A Python tool for automating German Elster tax declaration form filling using Claude AI. This tool helps you organize your tax data and generates step-by-step instructions for filling out Elster forms.

## Features

- 📋 Create and manage tax declarations with ease
- 💰 Track income sources and deductions
- 🤖 AI-powered form filling instructions using Claude
- ✅ Validate declarations against Elster requirements
- 📄 Export properly formatted data for Elster submission

## Installation

```bash
# Clone the repository
git clone https://github.com/anthropics/claude-quickstarts.git
cd claude-quickstarts/tax-declaration-elster

# Install dependencies
pip install -e ".[dev]"

# Set up environment
cp .env.example .env
# Add your ANTHROPIC_API_KEY to .env
```

## Setup & Development

```bash
# Install dependencies
pip install -e ".[dev]"

# Run tests
pytest

# Lint and format code
ruff check .
ruff format .

# Type check
pyright
```

## Usage

### Create a new tax declaration

```bash
elster-fill create --first-name Max --last-name Mustermann \
  --date-of-birth 1980-01-15 --tax-id 12345678900 \
  --street "Musterstraße 1" --city Berlin --postal-code 10115 \
  --year 2024
```

This creates a `declaration.json` file with your basic information.

### Add income and deductions

```bash
elster-fill add declaration.json \
  --income employment 50000 "Annual salary" \
  --income interest 500 "Bank interest" \
  --deduction work_expenses 1000 "Home office" \
  --deduction donations 500 "Charity donations"
```

### Generate form filling instructions

```bash
elster-fill generate declaration.json
```

This uses Claude AI to generate detailed, step-by-step instructions for filling out your Elster forms. The instructions will be saved to `declaration_instructions.txt`.

### Validate your declaration

```bash
elster-fill validate declaration.json
```

Validates your declaration data against Elster requirements and highlights any issues.

## Project Structure

```
tax-declaration-elster/
├── src/tax_declaration_elster/
│   ├── __init__.py
│   ├── types.py              # Data type definitions
│   ├── elster_handler.py     # Claude AI integration
│   └── cli.py                # Command-line interface
├── tests/
│   ├── test_types.py
│   └── test_elster_handler.py
├── pyproject.toml            # Project configuration
└── README.md                 # This file
```

## Code Style

- **Python**: snake_case for functions/variables, PascalCase for classes
- **Imports**: Organized with isort, combine-as-imports enabled
- **Error handling**: Custom error types for tool-specific errors
- **Type annotations**: All functions have type hints
- **Classes**: Use dataclasses for data structures

## Contributing

When making changes to files, please:

1. Update version in `src/tax_declaration_elster/__init__.py`
2. Add entries to CHANGELOG.md
3. Run tests: `pytest`
4. Format code: `ruff format .`
5. Check types: `pyright`

## License

See LICENSE file in the repository root.
