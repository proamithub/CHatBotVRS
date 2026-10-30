using System;
using HelpBot_Repo.IRepository;

namespace HelpBot_Repo
{
    public interface IUnitOfWork : IDisposable
    {
        IBotRepository BotRepo { get; }
        IAgentRepository AgentRepo { get; }
        IAdminRepository AdminRepo { get; }
    }
}
