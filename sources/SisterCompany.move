module MyAccount::SisterCompany{
    use std::string::{String,utf8};

    friend MyAccount::CompanyInfo;

    public(friend) fun get_company_name():String {
        utf8(b"company_name")
    }
}