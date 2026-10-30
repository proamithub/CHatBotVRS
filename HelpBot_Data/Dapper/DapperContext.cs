using HelpBot_Data.Dapper.Implementations;
using HelpBot_Data.Dapper.Interfaces;

namespace HelpBot_Data.Dapper
{
    public class DapperContext : IDapperContext
    {
        private readonly ISqlConnectionHelper _sqlConnectionHelper;
        private IProcedureHelper? _procedureHelper;

        public DapperContext(string connectionString)
        {
            _sqlConnectionHelper = new SqlConnectionHelper(connectionString);
        }

        public IProcedureHelper ProcedureHelper
        {
            get
            {
                if (_procedureHelper == null)
                {
                    _procedureHelper = new ProcedureHelper(_sqlConnectionHelper);
                }
                return _procedureHelper;
            }
        }
    }
}
