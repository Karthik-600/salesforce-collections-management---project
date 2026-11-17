import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getCustomerLoanDashboard from '@salesforce/apex/LoanManagementController.getCustomerLoanDashboard';

export default class CustomerLoanDetails extends LightningElement {
    @api recordId;

    dashboardData;
    errorMessage;
    isLoading = true;
    wiredResult;

    @wire(getCustomerLoanDashboard, { customerId: '$recordId' })
    wiredDashboard(result) {
        this.wiredResult = result;
        this.isLoading = false;

        if (result.data) {
            this.dashboardData = result.data;
            this.errorMessage = undefined;
        } else if (result.error) {
            this.dashboardData = undefined;
            this.errorMessage = this.extractErrorMessage(result.error);
        }
    }

    async handleRefresh() {
        if (!this.wiredResult) {
            return;
        }
        this.isLoading = true;
        try {
            await refreshApex(this.wiredResult);
        } catch (error) {
            this.errorMessage = this.extractErrorMessage(error);
        } finally {
            this.isLoading = false;
        }
    }

    get contactabilityDisplay() {
        return this.dashboardData?.customer?.contactabilityStatus || 'Status Pending';
    }

    get branchAndState() {
        const branch = this.dashboardData?.customer?.branch;
        const state = this.dashboardData?.customer?.state;
        if (branch && state) {
            return `${branch}, ${state}`;
        }
        return branch || state || 'Not Specified';
    }

    get addressDisplay() {
        return this.dashboardData?.customer?.address || 'No address on file';
    }

    get loanCountLabel() {
        const count = this.dashboardData?.loans?.length || 0;
        return `${count} ${count === 1 ? 'Account' : 'Accounts'}`;
    }

    get caseCountLabel() {
        const count = this.dashboardData?.collectionCases?.length || 0;
        return `${count} ${count === 1 ? 'Case' : 'Cases'}`;
    }

    get hasRiskAssessment() {
        return Boolean(this.dashboardData?.riskAssessment);
    }

    get riskLevelClass() {
        const level = this.dashboardData?.riskAssessment?.riskLevel;
        if (level === 'HIGH') {
            return 'field-value risk-high';
        }
        if (level === 'MEDIUM') {
            return 'field-value risk-medium';
        }
        return 'field-value risk-low';
    }

    extractErrorMessage(error) {
        if (!error) {
            return 'An unexpected error occurred while loading customer loan details.';
        }
        if (Array.isArray(error.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        if (error.body && typeof error.body.message === 'string') {
            return error.body.message;
        }
        return error.message || 'Unable to load customer loan details.';
    }
}
