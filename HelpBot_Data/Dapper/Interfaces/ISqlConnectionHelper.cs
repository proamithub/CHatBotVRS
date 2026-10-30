using System;
using System.Data;

namespace HelpBot_Data.Dapper.Interfaces
{
    public interface ISqlConnectionHelper : IDisposable
    {
        IDbConnection GetDbConnection();
    }
}
