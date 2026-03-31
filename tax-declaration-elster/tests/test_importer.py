"""Tests for data import functionality."""

import json
import tempfile
from pathlib import Path

from tax_declaration_elster.importer import DataImporter
from tax_declaration_elster.types import Property, TaxPayer


def test_import_personal_data() -> None:
    """Test importing personal data."""
    data = {
        "first_name": "Max",
        "last_name": "Mustermann",
        "date_of_birth": "1980-01-15",
        "tax_id": "12345678900",
        "street": "Musterstraße 1",
        "city": "Berlin",
        "postal_code": "10115",
    }

    taxpayer = DataImporter.import_personal_data(data)

    assert isinstance(taxpayer, TaxPayer)
    assert taxpayer.first_name == "Max"
    assert taxpayer.last_name == "Mustermann"
    assert taxpayer.tax_id == "12345678900"


def test_import_incomes() -> None:
    """Test importing income data."""
    data = [
        {"source": "employment", "amount": "50000.00", "description": "Salary"},
        {"source": "interest", "amount": "500,50", "description": "Bank interest"},
    ]

    incomes = DataImporter.import_incomes(data, year=2024)

    assert len(incomes) == 2
    assert incomes[0].amount == 50000.00
    assert incomes[1].amount == 500.50  # German comma format


def test_import_deductions() -> None:
    """Test importing deduction data."""
    data = [
        {"category": "work_expenses", "amount": "1000.00", "description": "Homeoffice"},
        {"category": "donations", "amount": "500,50", "description": "Charity"},
    ]

    deductions = DataImporter.import_deductions(data)

    assert len(deductions) == 2
    assert deductions[0].amount == 1000.00
    assert deductions[1].amount == 500.50


def test_import_properties() -> None:
    """Test importing property data."""
    data = [
        {
            "name": "Apartment Berlin",
            "address": "Schönhauser Allee 42",
            "postal_code": "10435",
            "city": "Berlin",
            "type": "apartment",
            "purchase_price": "450000.00",
            "purchase_date": "2018-06-15",
            "rental_income": "1200.00",
            "expense_repairs": "800",
            "expense_insurance": "450",
            "expense_utilities": "2100",
            "expense_loan_interest": "8500",
        }
    ]

    properties = DataImporter.import_properties(data)

    assert len(properties) == 1
    prop = properties[0]
    assert prop.name == "Apartment Berlin"
    assert prop.annual_rental_income() == 14400.00
    assert prop.total_expenses() == 11850.00
    assert prop.net_income() == 2550.00


def test_import_from_directory() -> None:
    """Test importing from directory structure."""
    # Create temporary directory structure
    with tempfile.TemporaryDirectory() as tmpdir:
        tmppath = Path(tmpdir)

        # Create personal data
        personal_data = {
            "first_name": "Test",
            "last_name": "User",
            "date_of_birth": "1990-01-01",
            "tax_id": "98765432100",
            "street": "Test Street 1",
            "city": "Test City",
            "postal_code": "12345",
        }

        with open(tmppath / "persoenliche_daten.json", "w") as f:
            json.dump(personal_data, f)

        # Create incomes CSV
        with open(tmppath / "einnahmen.csv", "w") as f:
            f.write("source,amount,description\n")
            f.write("employment,60000,Salary\n")

        # Create deductions CSV
        with open(tmppath / "werbungskosten.csv", "w") as f:
            f.write("category,amount,description\n")
            f.write("work_expenses,1500,Homeoffice\n")

        # Import
        declaration = DataImporter.from_directory(tmppath, year=2024)

        assert declaration.tax_payer.first_name == "Test"
        assert len(declaration.incomes) == 1
        assert declaration.incomes[0].amount == 60000.0
        assert len(declaration.deductions) == 1
        assert declaration.deductions[0].amount == 1500.0
