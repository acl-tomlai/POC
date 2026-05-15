namespace Pos.Api.Helpers;

public static class Roles
{
    public const string Admin = "Admin";
    public const string Manager = "Manager";
    public const string Cashier = "Cashier";

    public const string AdminOnly = Admin;
    public const string AdminOrManager = Admin + "," + Manager;
    public const string AllRoles = Admin + "," + Manager + "," + Cashier;
}
