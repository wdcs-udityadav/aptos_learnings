module MyAccount::CompanyInfo {
    use std::string::{String,utf8};

    struct Info has drop{
        c_name: String,
        c_owner: String
    }

    public fun get_info():Info{
        Info{
            c_name: MyAccount::SisterCompany::get_company_name(),
            c_owner: utf8(b"SisterCompany")
        }
    }

    #[test]
    fun test_company_info() {
       let info = get_info();
        assert!(info.c_owner == utf8(b"SisterCompany"),0);
        assert!(info.c_name == utf8(b"company_name"),0);
    }
}