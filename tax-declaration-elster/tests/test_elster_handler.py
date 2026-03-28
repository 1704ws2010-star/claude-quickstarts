"""Tests for Elster form handler."""

import os

from tax_declaration_elster.elster_handler import ElsterFormHandler
from tax_declaration_elster.types import (
    Deduction,
    Income,
    TaxDeclaration,
    TaxPayer,
)


def create_test_declaration() -> TaxDeclaration:
    """Create a test tax declaration."""
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
    declaration.deductions.append(
        Deduction(category="work_expenses", amount=1000.0)
    )

    return declaration


def test_extract_form_values() -> None:
    """Test extraction of form values with German formatting."""
    handler = ElsterFormHandler(api_key="test-key")

    test_data = {
        "income": 50000.50,
        "deduction": 1000.75,
        "active": True,
        "notes": "Test declaration",
    }

    extracted = handler.extract_form_values(test_data)

    assert extracted["income"] == "50000,50"
    assert extracted["deduction"] == "1000,75"
    assert extracted["active"] == "1"
    assert extracted["notes"] == "Test declaration"


def test_validate_form_data() -> None:
    """Test form data validation (requires API key)."""
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        # Skip test if API key not available
        return

    declaration = create_test_declaration()
    handler = ElsterFormHandler(api_key)

    result = handler.validate_form_data(declaration)

    assert "validation_report" in result
    assert "valid" in result
