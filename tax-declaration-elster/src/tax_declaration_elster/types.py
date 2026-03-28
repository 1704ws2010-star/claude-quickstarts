"""Type definitions for tax declaration data."""

from dataclasses import dataclass, field
from typing import Any, Optional


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
    special_cases: dict[str, Any] = field(default_factory=dict)

    def total_income(self) -> float:
        """Calculate total income."""
        return sum(income.amount for income in self.incomes)

    def total_deductions(self) -> float:
        """Calculate total deductions."""
        return sum(deduction.amount for deduction in self.deductions)

    def taxable_income(self) -> float:
        """Calculate taxable income."""
        return max(0, self.total_income() - self.total_deductions())
