using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using HelpBot_Model.DTO;
using HelpBot_Repo;

namespace HelpBot_UI.Controllers
{
    public class AccountController : Controller
    {
        private readonly IUnitOfWork _unitOfWork;

        public AccountController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: /Account/Login
        [HttpGet]
        public IActionResult Login(string? returnUrl = null)
        {
            if (User.Identity != null && User.Identity.IsAuthenticated)
            {
                if (User.IsInRole("Admin"))
                {
                    return RedirectToAction("Dashboard", "Admin");
                }
                return RedirectToAction("Dashboard", "Agent");
            }
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }

        // POST: /Account/Login
        [HttpPost]
        public async Task<IActionResult> Login([FromForm] AgentLoginRequestDTO model, string? returnUrl = null)
        {
            if (string.IsNullOrWhiteSpace(model.Email) || string.IsNullOrWhiteSpace(model.Password))
            {
                ViewBag.Error = "Please enter both Email and Password.";
                return View(model);
            }

            // Authenticate using Stored Procedure sp_AgentLogin via UnitOfWork
            var agent = await _unitOfWork.AgentRepo.LoginAgentAsync(model.Email.Trim(), model.Password.Trim());

            if (agent == null)
            {
                ViewBag.Error = "Invalid Email or Password! Please try again.";
                return View(model);
            }

            // Create Authentication Claims
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, agent.AgentId.ToString()),
                new Claim(ClaimTypes.Name, agent.Name),
                new Claim(ClaimTypes.Email, agent.Email),
                new Claim(ClaimTypes.Role, agent.Role),
                new Claim("ThemeColor", agent.ThemeColor ?? "emerald")
            };

            bool isAdmin = agent.Role.Equals("Admin", StringComparison.OrdinalIgnoreCase) || 
                           agent.Role.Contains("Admin", StringComparison.OrdinalIgnoreCase);

            if (isAdmin && !claims.Any(c => c.Type == ClaimTypes.Role && c.Value == "Admin"))
            {
                claims.Add(new Claim(ClaimTypes.Role, "Admin"));
            }

            var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var authProperties = new AuthenticationProperties
            {
                IsPersistent = true,
                ExpiresUtc = DateTimeOffset.UtcNow.AddHours(8)
            };

            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                new ClaimsPrincipal(claimsIdentity),
                authProperties
            );

            // Set agent online in DB
            await _unitOfWork.AgentRepo.SetAgentOnlineStatusAsync(agent.AgentId, true);

            if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
            {
                return Redirect(returnUrl);
            }

            if (isAdmin)
            {
                return RedirectToAction("Dashboard", "Admin");
            }

            return RedirectToAction("Dashboard", "Agent");
        }

        // GET: /Account/Logout
        [HttpGet]
        public async Task<IActionResult> Logout()
        {
            if (int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out int agentId))
            {
                await _unitOfWork.AgentRepo.SetAgentOnlineStatusAsync(agentId, false);
            }
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction("Login", "Account");
        }
    }
}
