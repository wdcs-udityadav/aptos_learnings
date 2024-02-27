module MyAccount::Company{
    use std::vector;

    struct Company has key,drop{
        employees: vector<Employee>
    }

    struct Employee has store,copy,drop{
        e_id: u8,
        e_age: u8,
        e_income:u8
    }

    public fun initialize_company():Company {
        Company{employees: vector::empty<Employee>()}
    }

    public fun create_employee(id:u8,age:u8,income:u8, employees:&mut vector<Employee>):Employee{
        let new_employee = Employee{
            e_id: id,
            e_age: age,
            e_income:income
        };
        add_employee(copy new_employee, employees);
        return new_employee
    }

    fun add_employee(employee:Employee, employees:&mut vector<Employee>) {
        vector::push_back(employees, employee);
    }

    public fun is_employee_age_even(employee:Employee):bool {
        if(employee.e_age%2 == 0){ true}else{false}
    }

    public fun decrease_income(employee:&mut Employee, decrease_by:u8) {
        employee.e_income = employee.e_income - decrease_by;
    }

    public fun increase_income(employee:&mut Employee, increase_by:u8) {
        employee.e_income = employee.e_income + increase_by;
    }

    public fun multiply_income(employee:&mut Employee, factor:u8) {
        employee.e_income = employee.e_income * factor;
    }

    public fun devide_income(employee:&mut Employee, factor:u8) {
        employee.e_income = employee.e_income / factor;
    }

    #[test]
    fun test_flow() {
        let company = initialize_company();
        let created_employee = create_employee(1, 30, 60, &mut company.employees);
        assert!(is_employee_age_even(created_employee),0);
        
        decrease_income(&mut created_employee, 10);
        assert!(created_employee.e_income == 50,0);

        increase_income(&mut created_employee, 5);
        assert!(created_employee.e_income == 55,0);

        multiply_income(&mut created_employee, 2);
        assert!(created_employee.e_income == 110,0);

        devide_income(&mut created_employee, 11);
        assert!(created_employee.e_income == 10,0);        
    }
}