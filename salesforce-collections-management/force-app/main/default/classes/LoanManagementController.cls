/**
 * @description       : Lightning Web Component Apex Controller for customerLoanDetails.
 *                      Consolidates Customer, Loan Accounts, Collection Cases, and Risk Analysis
 *                      into a single payload so telecallers have zero tab switching.
 * @group             : Collections Management
 * @reference         : Reconstructed reference implementation for Srinidhi Associates
 */
public with sharing class LoanManagementController {

    /**
     * @description Consolidated DTO returned to the customerLoanDetails LWC.
     */
    public class CustomerLoanDashboardDTO {
        @AuraEnabled public CustomerSummary customer { get; set; }
        @AuraEnabled public List<LoanSummary> loans { get; set; }
        @AuraEnabled public List<CollectionCaseSummary> collectionCases { get; set; }
        @AuraEnabled public RiskAnalysisService.RiskAssessmentResult riskAssessment { get; set; }
        @AuraEnabled public Boolean hasLoans { get; set; }
        @AuraEnabled public Boolean hasCases { get; set; }

        public CustomerLoanDashboardDTO() {
            this.loans = new List<LoanSummary>();
            this.collectionCases = new List<CollectionCaseSummary>();
            this.hasLoans = false;
            this.hasCases = false;
        }
    }

    public class CustomerSummary {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String phoneNumber { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String address { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String branch { get; set; }
        @AuraEnabled public String contactabilityStatus { get; set; }
    }

    public class LoanSummary {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String loanNumber { get; set; }
        @AuraEnabled public Decimal loanAmount { get; set; }
        @AuraEnabled public Decimal outstandingAmount { get; set; }
        @AuraEnabled public Decimal amountPaid { get; set; }
        @AuraEnabled public Decimal interestRate { get; set; }
        @AuraEnabled public Date dueDate { get; set; }
        @AuraEnabled public String loanStatus { get; set; }
        @AuraEnabled public String riskLevel { get; set; }
        @AuraEnabled public Decimal collectionEfficiency { get; set; }
        @AuraEnabled public Decimal daysOverdue { get; set; }
    }

    public class CollectionCaseSummary {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String caseNumber { get; set; }
        @AuraEnabled public Id loanAccountId { get; set; }
        @AuraEnabled public String loanNumber { get; set; }
        @AuraEnabled public String caseStatus { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public String assignedTelecallerName { get; set; }
        @AuraEnabled public String assignedFieldExecutiveName { get; set; }
        @AuraEnabled public Date nextFollowUpDate { get; set; }
        @AuraEnabled public String collectionStatus { get; set; }
        @AuraEnabled public String escalationReason { get; set; }
    }

    /**
     * @description Retrieves consolidated Customer, Loan Accounts, Collection Cases,
     *              and Risk Assessment for the specified Customer__c record.
     * @param customerId Id of the Customer__c record
     * @return CustomerLoanDashboardDTO consolidated data for the LWC
     */
    @AuraEnabled(cacheable=true)
    public static CustomerLoanDashboardDTO getCustomerLoanDashboard(Id customerId) {
        if (customerId == null) {
            throw new AuraHandledException('Customer record ID is required.');
        }

        if (!Schema.sObjectType.Customer__c.isAccessible() ||
            !Schema.sObjectType.Loan_Account__c.isAccessible() ||
            !Schema.sObjectType.Collection_Case__c.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to view customer collection records.');
        }

        try {
            List<Customer__c> customers = [
                SELECT Id, Name, Phone_Number__c, Email__c, Address__c,
                       State__c, Branch__c, Contactability_Status__c
                FROM Customer__c
                WHERE Id = :customerId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (customers.isEmpty()) {
                throw new AuraHandledException('Customer record not found.');
            }

            Customer__c customerRec = customers[0];
            CustomerLoanDashboardDTO dto = new CustomerLoanDashboardDTO();
            dto.customer = mapCustomer(customerRec);

            List<Loan_Account__c> loanRecords = [
                SELECT Id, Name, Customer__c, Loan_Amount__c, Outstanding_Amount__c,
                       Amount_Paid__c, Interest_Rate__c, Due_Date__c, Loan_Status__c,
                       Risk_Level__c, Collection_Efficiency__c, Days_Overdue__c
                FROM Loan_Account__c
                WHERE Customer__c = :customerId
                WITH SECURITY_ENFORCED
                ORDER BY Outstanding_Amount__c DESC, CreatedDate DESC
            ];

            for (Loan_Account__c loan : loanRecords) {
                dto.loans.add(mapLoan(loan));
            }
            dto.hasLoans = !dto.loans.isEmpty();

            List<Collection_Case__c> caseRecords = [
                SELECT Id, Name, Loan_Account__c, Loan_Account__r.Name, Case_Status__c,
                       Priority__c, Assigned_Telecaller__r.Name, Assigned_Field_Executive__r.Name,
                       Next_Follow_Up_Date__c, Collection_Status__c, Escalation_Reason__c
                FROM Collection_Case__c
                WHERE Customer__c = :customerId
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
            ];

            for (Collection_Case__c cCase : caseRecords) {
                dto.collectionCases.add(mapCase(cCase));
            }
            dto.hasCases = !dto.collectionCases.isEmpty();

            if (!loanRecords.isEmpty()) {
                dto.riskAssessment = RiskAnalysisService.analyzeLoanRisk(
                    loanRecords[0],
                    customerRec,
                    caseRecords.isEmpty() ? null : caseRecords[0]
                );
            }

            return dto;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            throw new AuraHandledException('Unable to load customer loan details: ' + ex.getMessage());
        }
    }

    /**
     * @description Refreshes risk analysis for a specific Loan_Account__c record on demand.
     * @param loanAccountId Id of the Loan_Account__c record
     * @return RiskAnalysisService.RiskAssessmentResult
     */
    @AuraEnabled
    public static RiskAnalysisService.RiskAssessmentResult refreshLoanRiskAnalysis(Id loanAccountId) {
        if (loanAccountId == null) {
            throw new AuraHandledException('Loan Account ID is required.');
        }

        try {
            return RiskAnalysisService.evaluateAndPersistRisk(loanAccountId);
        } catch (Exception ex) {
            throw new AuraHandledException('Unable to refresh risk analysis: ' + ex.getMessage());
        }
    }

    private static CustomerSummary mapCustomer(Customer__c rec) {
        CustomerSummary summary = new CustomerSummary();
        summary.id = rec.Id;
        summary.name = rec.Name;
        summary.phoneNumber = rec.Phone_Number__c;
        summary.email = rec.Email__c;
        summary.address = rec.Address__c;
        summary.state = rec.State__c;
        summary.branch = rec.Branch__c;
        summary.contactabilityStatus = rec.Contactability_Status__c;
        return summary;
    }

    private static LoanSummary mapLoan(Loan_Account__c rec) {
        LoanSummary summary = new LoanSummary();
        summary.id = rec.Id;
        summary.loanNumber = rec.Name;
        summary.loanAmount = rec.Loan_Amount__c != null ? rec.Loan_Amount__c : 0;
        summary.outstandingAmount = rec.Outstanding_Amount__c != null ? rec.Outstanding_Amount__c : 0;
        summary.amountPaid = rec.Amount_Paid__c != null ? rec.Amount_Paid__c : 0;
        summary.interestRate = rec.Interest_Rate__c;
        summary.dueDate = rec.Due_Date__c;
        summary.loanStatus = rec.Loan_Status__c;
        summary.riskLevel = rec.Risk_Level__c;
        summary.collectionEfficiency = rec.Collection_Efficiency__c != null ? rec.Collection_Efficiency__c : 0;
        summary.daysOverdue = rec.Days_Overdue__c != null ? rec.Days_Overdue__c : 0;
        return summary;
    }

    private static CollectionCaseSummary mapCase(Collection_Case__c rec) {
        CollectionCaseSummary summary = new CollectionCaseSummary();
        summary.id = rec.Id;
        summary.caseNumber = rec.Name;
        summary.loanAccountId = rec.Loan_Account__c;
        summary.loanNumber = rec.Loan_Account__r != null ? rec.Loan_Account__r.Name : null;
        summary.caseStatus = rec.Case_Status__c;
        summary.priority = rec.Priority__c;
        summary.assignedTelecallerName = rec.Assigned_Telecaller__r != null ? rec.Assigned_Telecaller__r.Name : 'Unassigned';
        summary.assignedFieldExecutiveName = rec.Assigned_Field_Executive__r != null ? rec.Assigned_Field_Executive__r.Name : 'Unassigned';
        summary.nextFollowUpDate = rec.Next_Follow_Up_Date__c;
        summary.collectionStatus = rec.Collection_Status__c;
        summary.escalationReason = rec.Escalation_Reason__c;
        return summary;
    }
}
