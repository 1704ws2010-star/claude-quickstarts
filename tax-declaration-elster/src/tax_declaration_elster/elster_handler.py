"""Handler for Elster form interactions and data submission."""

from dataclasses import asdict
from typing import Any

from anthropic import Anthropic

from .types import Income, TaxDeclaration


class ElsterFormHandler:
    """Handles interaction with Elster forms using Claude AI."""

    def __init__(self, api_key: str):
        """Initialize the Elster form handler.

        Args:
            api_key: Anthropic API key
        """
        self.client = Anthropic()

    def generate_form_filling_instructions(
        self, declaration: TaxDeclaration
    ) -> dict[str, Any]:
        """Generate step-by-step form filling instructions using Claude.

        Args:
            declaration: Tax declaration data

        Returns:
            Dictionary containing form filling instructions and field mappings
        """
        declaration_summary = self._format_declaration_for_claude(declaration)

        message = self.client.messages.create(
            model="claude-opus-4-6",
            max_tokens=2048,
            messages=[
                {
                    "role": "user",
                    "content": f"""You are an expert in German Elster tax forms.
Analyze this tax declaration and provide clear, step-by-step instructions for filling
out the corresponding Elster forms:

{declaration_summary}

For each field in the Elster form:
1. Specify the field name/location
2. Provide the exact value to enter
3. Note any special formatting requirements
4. Include relevant line numbers from tax forms (Anlage, etc.)

Format your response as a structured list with clear sections.""",
                }
            ],
        )

        return {
            "instructions": message.content[0].text,
            "declaration_data": asdict(declaration),
        }

    def validate_form_data(self, declaration: TaxDeclaration) -> dict[str, Any]:
        """Validate tax declaration data against Elster requirements.

        Args:
            declaration: Tax declaration data to validate

        Returns:
            Validation results with any errors or warnings
        """
        validation_prompt = self._create_validation_prompt(declaration)

        message = self.client.messages.create(
            model="claude-opus-4-6",
            max_tokens=1024,
            messages=[{"role": "user", "content": validation_prompt}],
        )

        return {
            "valid": "errors" not in message.content[0].text.lower(),
            "validation_report": message.content[0].text,
        }

    def extract_form_values(self, form_data: dict[str, Any]) -> dict[str, str]:
        """Extract and format values from form data for Elster submission.

        Args:
            form_data: Raw form data dictionary

        Returns:
            Formatted values ready for Elster submission
        """
        # Convert data types and apply Elster-specific formatting
        extracted = {}

        for key, value in form_data.items():
            if value is None:
                extracted[key] = ""
            elif isinstance(value, float):
                # German decimal format: comma as decimal separator
                extracted[key] = f"{value:.2f}".replace(".", ",")
            elif isinstance(value, bool):
                extracted[key] = "1" if value else "0"
            else:
                extracted[key] = str(value).strip()

        return extracted

    def _format_declaration_for_claude(self, declaration: TaxDeclaration) -> str:
        """Format tax declaration data as readable text for Claude."""
        lines = [
            f"Tax Year: {declaration.year}",
            f"Taxpayer: {declaration.tax_payer.first_name} {declaration.tax_payer.last_name}",
            f"Tax ID: {declaration.tax_payer.tax_id}",
            "",
            "Income Sources:",
        ]

        for income in declaration.incomes:
            lines.append(
                f"  - {income.source}: €{income.amount:,.2f} ({income.description or 'N/A'})"
            )

        lines.append("\nDeductions:")
        for deduction in declaration.deductions:
            lines.append(
                f"  - {deduction.category}: €{deduction.amount:,.2f} ({deduction.description or 'N/A'})"
            )

        lines.append("")
        lines.append(f"Total Income: €{declaration.total_income():,.2f}")
        lines.append(f"Total Deductions: €{declaration.total_deductions():,.2f}")
        lines.append(f"Taxable Income: €{declaration.taxable_income():,.2f}")

        if declaration.special_cases:
            lines.append("\nSpecial Cases:")
            for case, details in declaration.special_cases.items():
                lines.append(f"  - {case}: {details}")

        return "\n".join(lines)

    def _create_validation_prompt(self, declaration: TaxDeclaration) -> str:
        """Create a validation prompt for Claude."""
        declaration_text = self._format_declaration_for_claude(declaration)

        return f"""As a German tax expert, validate this tax declaration for Elster submission.
Check for:
1. Missing required fields
2. Invalid data formats
3. Incomplete income/deduction documentation
4. Compliance with German tax law
5. Common Elster submission errors

Declaration:
{declaration_text}

Provide a detailed validation report."""
