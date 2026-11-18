// Anonymous Apex script to seed Srinidhi Associates sample records in a Scratch Org / Sandbox
// Run with: sf apex run --file scripts/apex/seedSampleData.apex

Customer__c cust1 = new Customer__c(
    Name = 'Rajesh Kumar',
    Phone_Number__c = '+919840012345',
    Email__c = 'rajesh.kumar@example.com',
    Address__c = '42 Anna Salai, Teynampet, Chennai',
    State__c = 'Tamil Nadu',
    Branch__c = 'Chennai Central',
    Contactability_Status__c = 'Contactable'
);
Customer__c cust2 = new Customer__c(
    Name = 'Suresh Babu',
    Phone_Number__c = '+919841098765',
    Email__c = 'suresh.babu@example.com',
    Address__c = '18 MG Road, Indiranagar, Bengaluru',
    State__c = 'Karnataka',
    Branch__c = 'Bengaluru East',
    Contactability_Status__c = 'Non-Contactable'
);
insert new List<Customer__c>{ cust1, cust2 };

Loan_Account__c loan1 = new Loan_Account__c(
    Customer__c = cust1.Id,
    Loan_Amount__c = 500000,
    Outstanding_Amount__c = 320000,
    Amount_Paid__c = 180000,
    Interest_Rate__c = 12.5,
    Due_Date__c = Date.today().addDays(-45),
    Loan_Status__c = 'Overdue',
    Risk_Level__c = 'MEDIUM'
);
Loan_Account__c loan2 = new Loan_Account__c(
    Customer__c = cust2.Id,
    Loan_Amount__c = 750000,
    Outstanding_Amount__c = 690000,
    Amount_Paid__c = 60000,
    Interest_Rate__c = 14.0,
    Due_Date__c = Date.today().addDays(-120),
    Loan_Status__c = 'NPA',
    Risk_Level__c = 'HIGH'
);
insert new List<Loan_Account__c>{ loan1, loan2 };

Collection_Case__c case1 = new Collection_Case__c(
    Customer__c = cust1.Id,
    Loan_Account__c = loan1.Id,
    Case_Status__c = 'In Progress',
    Priority__c = 'High',
    Next_Follow_Up_Date__c = Date.today().addDays(2),
    Collection_Status__c = 'Promise to Pay'
);
Collection_Case__c case2 = new Collection_Case__c(
    Customer__c = cust2.Id,
    Loan_Account__c = loan2.Id,
    Case_Status__c = 'Escalated',
    Priority__c = 'Critical',
    Escalation_Reason__c = 'Customer unreachable for 120 days; field visit required',
    Next_Follow_Up_Date__c = Date.today().addDays(1),
    Collection_Status__c = 'Non-Contactable'
);
insert new List<Collection_Case__c>{ case1, case2 };

System.debug('Seeded 2 Customers, 2 Loan Accounts, and 2 Collection Cases successfully.');
