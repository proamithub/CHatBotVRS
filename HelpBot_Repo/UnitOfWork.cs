using System;
using HelpBot_Data.Dapper;
using HelpBot_Repo.IRepository;
using HelpBot_Repo.Repository;

namespace HelpBot_Repo
{
    public class UnitOfWork : IUnitOfWork
    {
        private readonly IDapperContext _dapperContext;
        private IBotRepository? _botRepo;
        private IAgentRepository? _agentRepo;
        private IAdminRepository? _adminRepo;

        public UnitOfWork(IDapperContext dapperContext)
        {
            _dapperContext = dapperContext;
        }

        public IBotRepository BotRepo
        {
            get
            {
                if (_botRepo == null)
                {
                    _botRepo = new BotRepository(_dapperContext);
                }
                return _botRepo;
            }
        }

        public IAgentRepository AgentRepo
        {
            get
            {
                if (_agentRepo == null)
                {
                    _agentRepo = new AgentRepository(_dapperContext);
                }
                return _agentRepo;
            }
        }

        public IAdminRepository AdminRepo
        {
            get
            {
                if (_adminRepo == null)
                {
                    _adminRepo = new AdminRepository(_dapperContext);
                }
                return _adminRepo;
            }
        }

        public void Dispose()
        {
            GC.SuppressFinalize(this);
        }
    }
}
