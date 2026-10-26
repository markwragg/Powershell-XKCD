function Read-XKCDConsoleKey {
    <#
    .SYNOPSIS
        Blocks until a key is pressed and returns it, without echoing it to the console. A thin wrapper around
        [Console]::ReadKey so Start-XKCD's input handling can be mocked in tests.
    #>
    [cmdletbinding()]
    Param()

    [Console]::ReadKey($true)
}
