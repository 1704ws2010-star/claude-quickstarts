"""Type definitions for tax declaration data."""

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Optional


class ExpenseCategory(str, Enum):
    """Categories for tax deductible expenses."""

    REPAIRS = "repairs"  # Reparaturen/Instandhaltung
    INSURANCE = "insurance"  # Versicherungen
    MANAGEMENT = "management"  # Verwaltungsgebühren
    UTILITIES = "utilities"  # Nebenkosten (Wasser, Strom, Heizung)
    LOAN_INTEREST = "loan_interest"  # Darlehenskonten
    CLEANING = "cleaning"  # Reinigung
    GARDENING = "gardening"  # Gartenpflege
    BROKER_COMMISSION = "broker_commission"  # Makler/Verwaltung
    TAX_ADVICE = "tax_advice"  # Steuerberatung
    DEPRECIATION = "depreciation"  # Abschreibung
    OTHER = "other"  # Sonstige


@dataclass
class Property:
    """Rental property information."""

    name: str
    address: str
    postal_code: str
    city: str
    property_type: str  # "apartment", "house", "commercial"
    purchase_price: float
    purchase_date: str  # YYYY-MM-DD
    rental_income_monthly: float
    expenses: dict[ExpenseCategory, float] = field(default_factory=dict)
    notes: Optional[str] = None

    def annual_rental_income(self) -> float:
        """Calculate annual rental income."""
        return self.rental_income_monthly * 12

    def total_expenses(self) -> float:
        """Calculate total expenses."""
        return sum(self.expenses.values())

    def net_income(self) -> float:
        """Calculate net income after expenses."""
        return self.annual_rental_income() - self.total_expenses()


@dataclass
class TaxPayer:
    """Personal tax payer information."""

    first_name: str
    last_name: str
    date_of_birth: str  # YYYY-MM-DD
    tax_id: str
    street: str
    city: str
    postal_code: str
    email: Optional[str] = None
    phone: Optional[str] = None


@dataclass
class Income:
    """Income information."""

    source: str  # e.g., "employment", "self_employment", "capital_gains"
    amount: float
    year: int
    description: Optional[str] = None
    additional_data: dict[str, Any] = field(default_factory=dict)


@dataclass
class Deduction:
    """Tax deduction information."""

    category: str  # e.g., "work_expenses", "donations", "training"
    amount: float
    description: Optional[str] = None
    receipts: list[str] = field(default_factory=list)


@dataclass
class TaxDeclaration:
    """Complete tax declaration data."""

    tax_payer: TaxPayer
    year: int
    incomes: list[Income] = field(default_factory=list)
    deductions: list[Deduction] = field(default_factory=list)
    properties: list[Property] = field(default_factory=list)
    special_cases: dict[str, Any] = field(default_factory=dict)

    def total_income(self) -> float:
        """Calculate total income from all sources."""
        employment_income = sum(income.amount for income in self.incomes)
        property_income = sum(prop.net_income() for prop in self.properties)
        return employment_income + property_income

    def total_rental_income(self) -> float:
        """Calculate total rental income."""
        return sum(prop.annual_rental_income() for prop in self.properties)

    def total_property_expenses(self) -> float:
        """Calculate total property expenses."""
        return sum(prop.total_expenses() for prop in self.properties)

    def total_deductions(self) -> float:
        """Calculate total personal deductions."""
        return sum(deduction.amount for deduction in self.deductions)

    def taxable_income(self) -> float:
        """Calculate taxable income."""
        return max(0, self.total_income() - self.total_deductions())
