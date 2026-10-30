using HelpBot_Data.Dapper.Interfaces;

namespace HelpBot_Data.Dapper
{
    public interface IDapperContext
    {
        IProcedureHelper ProcedureHelper { get; }
    }
}
