"""Command-line interface for tax declaration form filling."""

import json
import os
import sys
from pathlib import Path
from typing import Any

import click
from dotenv import load_dotenv

from .elster_handler import ElsterFormHandler
from .importer import DataImporter
from .types import Deduction, Income, TaxDeclaration, TaxPayer


@click.group()
def main() -> None:
    """Elster tax declaration form filling tool."""
    load_dotenv()


@main.command()
@click.option(
    "--first-name", prompt="First name", help="Taxpayer first name"
)
@click.option("--last-name", prompt="Last name", help="Taxpayer last name")
@click.option(
    "--date-of-birth",
    prompt="Date of birth (YYYY-MM-DD)",
    help="Date of birth",
)
@click.option("--tax-id", prompt="Tax ID", help="German tax ID")
@click.option("--street", prompt="Street", help="Street address")
@click.option("--city", prompt="City", help="City")
@click.option("--postal-code", prompt="Postal code", help="Postal code")
@click.option("--year", type=int, prompt="Tax year", help="Tax declaration year")
@click.option(
    "--output",
    type=click.Path(),
    default="declaration.json",
    help="Output file for declaration",
)
def create(
    first_name: str,
    last_name: str,
    date_of_birth: str,
    tax_id: str,
    street: str,
    city: str,
    postal_code: str,
    year: int,
    output: str,
) -> None:
    """Create a new tax declaration."""
    tax_payer = TaxPayer(
        first_name=first_name,
        last_name=last_name,
        date_of_birth=date_of_birth,
        tax_id=tax_id,
        street=street,
        city=city,
        postal_code=postal_code,
    )

    declaration = TaxDeclaration(tax_payer=tax_payer, year=year)

    # Save to file
    with open(output, "w") as f:
        json.dump(
            {
                "tax_payer": declaration.tax_payer.__dict__,
                "year": declaration.year,
                "incomes": [asdict(i) for i in declaration.incomes],
                "deductions": [asdict(d) for d in declaration.deductions],
            },
            f,
            indent=2,
            default=str,
        )

    click.echo(f"✓ Declaration created: {output}")


@main.command()
@click.argument("file", type=click.Path(exists=True))
@click.option(
    "--income",
    "incomes",
    multiple=True,
    nargs=3,
    type=(str, float, str),
    help="Income: source amount description",
)
@click.option(
    "--deduction",
    "deductions",
    multiple=True,
    nargs=3,
    type=(str, float, str),
    help="Deduction: category amount description",
)
def add(
    file: str,
    incomes: tuple[tuple[str, float, str], ...],
    deductions: tuple[tuple[str, float, str], ...],
) -> None:
    """Add income and deductions to a declaration."""
    with open(file) as f:
        data = json.load(f)

    # Load existing declaration
    tax_payer = TaxPayer(**data["tax_payer"])
    declaration = TaxDeclaration(tax_payer=tax_payer, year=data["year"])

    # Add incomes from CLI options
    for source, amount, description in incomes:
        declaration.incomes.append(
            Income(source=source, amount=amount, year=data["year"], description=description)
        )

    # Add deductions from CLI options
    for category, amount, description in deductions:
        declaration.deductions.append(
            Deduction(category=category, amount=amount, description=description)
        )

    # Save updated declaration
    with open(file, "w") as f:
        json.dump(
            {
                "tax_payer": declaration.tax_payer.__dict__,
                "year": declaration.year,
                "incomes": [vars(i) for i in declaration.incomes],
                "deductions": [vars(d) for d in declaration.deductions],
            },
            f,
            indent=2,
            default=str,
        )

    click.echo(f"✓ Updated: {file}")
    click.echo(f"  Total income: €{declaration.total_income():,.2f}")
    click.echo(f"  Total deductions: €{declaration.total_deductions():,.2f}")
    click.echo(f"  Taxable income: €{declaration.taxable_income():,.2f}")


@main.command()
@click.argument("file", type=click.Path(exists=True))
def generate(file: str) -> None:
    """Generate form filling instructions using Claude AI."""
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        click.echo("Error: ANTHROPIC_API_KEY not set", err=True)
        sys.exit(1)

    with open(file) as f:
        data = json.load(f)

    # Reconstruct declaration object
    tax_payer = TaxPayer(**data["tax_payer"])
    declaration = TaxDeclaration(tax_payer=tax_payer, year=data["year"])

    for income_data in data.get("incomes", []):
        declaration.incomes.append(Income(**income_data))

    for deduction_data in data.get("deductions", []):
        declaration.deductions.append(Deduction(**deduction_data))

    handler = ElsterFormHandler(api_key)
    click.echo("Generating form filling instructions...")

    result = handler.generate_form_filling_instructions(declaration)

    output_file = Path(file).stem + "_instructions.txt"
    with open(output_file, "w") as f:
        f.write(result["instructions"])

    click.echo(f"✓ Instructions saved: {output_file}")


@main.command()
@click.argument("file", type=click.Path(exists=True))
def validate(file: str) -> None:
    """Validate declaration data against Elster requirements."""
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        click.echo("Error: ANTHROPIC_API_KEY not set", err=True)
        sys.exit(1)

    with open(file) as f:
        data = json.load(f)

    tax_payer = TaxPayer(**data["tax_payer"])
    declaration = TaxDeclaration(tax_payer=tax_payer, year=data["year"])

    for income_data in data.get("incomes", []):
        declaration.incomes.append(Income(**income_data))

    for deduction_data in data.get("deductions", []):
        declaration.deductions.append(Deduction(**deduction_data))

    handler = ElsterFormHandler(api_key)
    click.echo("Validating declaration...")

    result = handler.validate_form_data(declaration)

    click.echo(result["validation_report"])

    if result["valid"]:
        click.echo("✓ Declaration is valid for Elster submission")
    else:
        click.echo("✗ Declaration has issues - review above", err=True)
        sys.exit(1)


@main.command()
@click.argument("directory", type=click.Path(exists=True))
@click.option("--year", type=int, default=2025, help="Tax year")
@click.option(
    "--output",
    type=click.Path(),
    default="declaration_imported.json",
    help="Output file for imported declaration",
)
def import_data(directory: str, year: int, output: str) -> None:
    """Import tax declaration from data directory.

    Expects directory structure:
    - persoenliche_daten.json
    - einnahmen.csv/.json/.xlsx
    - werbungskosten.csv/.json/.xlsx
    - immobilien/*.json/*.csv
    """
    try:
        click.echo(f"📂 Importing from: {directory}")
        declaration = DataImporter.from_directory(Path(directory), year=year)

        if not declaration:
            click.echo("Error: Could not import declaration", err=True)
            sys.exit(1)

        # Save to file
        with open(output, "w", encoding="utf-8") as f:
            json.dump(
                {
                    "tax_payer": vars(declaration.tax_payer),
                    "year": declaration.year,
                    "incomes": [vars(i) for i in declaration.incomes],
                    "deductions": [vars(d) for d in declaration.deductions],
                    "properties": [vars(p) for p in declaration.properties],
                },
                f,
                indent=2,
                default=str,
            )

        click.echo(f"✓ Imported to: {output}\n")

        # Summary
        click.echo("📊 SUMMARY:")
        click.echo(f"  Taxpayer: {declaration.tax_payer.first_name} {declaration.tax_payer.last_name}")
        click.echo(f"  Year: {declaration.year}\n")

        click.echo(f"💰 INCOME:")
        for income in declaration.incomes:
            click.echo(f"  • {income.source}: €{income.amount:,.2f}")
        click.echo(f"  Total: €{sum(i.amount for i in declaration.incomes):,.2f}\n")

        if declaration.properties:
            click.echo(f"🏠 PROPERTIES ({len(declaration.properties)}):")
            for prop in declaration.properties:
                click.echo(f"  • {prop.name}: €{prop.annual_rental_income():,.2f} - €{prop.total_expenses():,.2f} = €{prop.net_income():,.2f}")
            click.echo(f"  Total net: €{sum(p.net_income() for p in declaration.properties):,.2f}\n")

        click.echo(f"📉 DEDUCTIONS:")
        for deduction in declaration.deductions:
            click.echo(f"  • {deduction.category}: €{deduction.amount:,.2f}")
        click.echo(f"  Total: €{sum(d.amount for d in declaration.deductions):,.2f}\n")

        click.echo(f"📊 TOTALS:")
        click.echo(f"  Total Income: €{declaration.total_income():,.2f}")
        click.echo(f"  Total Deductions: €{declaration.total_deductions():,.2f}")
        click.echo(f"  Taxable Income: €{declaration.taxable_income():,.2f}")

    except FileNotFoundError as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)
    except Exception as e:
        click.echo(f"Error importing data: {e}", err=True)
        sys.exit(1)


def asdict(obj: object) -> dict:
    """Convert dataclass instance to dictionary."""
    if hasattr(obj, "__dict__"):
        return obj.__dict__
    return {}


if __name__ == "__main__":
    main()
