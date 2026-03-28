"""Tests for tax declaration data types."""

from tax_declaration_elster.types import (
    Deduction,
    Income,
    TaxDeclaration,
    TaxPayer,
)


def test_tax_payer_creation() -> None:
    """Test creating a taxpayer."""
    taxpayer = TaxPayer(
        first_name="Max",
        last_name="Mustermann",
        date_of_birth="1980-01-15",
        tax_id="12345678900",
        street="Musterstraße 1",
        city="Berlin",
        postal_code="10115",
    )

    assert taxpayer.first_name == "Max"
    assert taxpayer.last_name == "Mustermann"
    assert taxpayer.tax_id == "12345678900"


def test_income_creation() -> None:
    """Test creating income entries."""
    income = Income(
        source="employment",
        amount=50000.00,
        year=2024,
        description="Annual salary",
    )

    assert income.source == "employment"
    assert income.amount == 50000.00


def test_deduction_creation() -> None:
    """Test creating deductions."""
    deduction = Deduction(
        category="work_expenses",
        amount=1000.00,
        description="Home office",
    )

    assert deduction.category == "work_expenses"
    assert deduction.amount == 1000.00


def test_tax_declaration_calculations() -> None:
    """Test tax declaration calculations."""
    taxpayer = TaxPayer(
        first_name="Max",
        last_name="Mustermann",
        date_of_birth="1980-01-15",
        tax_id="12345678900",
        street="Musterstraße 1",
        city="Berlin",
        postal_code="10115",
    )

    declaration = TaxDeclaration(taxpayer=taxpayer, year=2024)
    declaration.incomes.append(
        Income(source="employment", amount=50000.0, year=2024)
    )
    declaration.incomes.append(
        Income(source="interest", amount=500.0, year=2024)
    )
    declaration.deductions.append(
        Deduction(category="work_expenses", amount=1000.0)
    )

    assert declaration.total_income() == 50500.0
    assert declaration.total_deductions() == 1000.0
    assert declaration.taxable_income() == 49500.0
