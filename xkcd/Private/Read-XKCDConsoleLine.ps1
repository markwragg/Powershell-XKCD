function Read-XKCDConsoleLine {
    <#
    .SYNOPSIS
        Blocks until Enter is pressed and returns the line of text typed before it (with normal echo/editing,
        unlike Read-XKCDConsoleKey). A thin wrapper around [Console]::ReadLine so Start-XKCD's -Number prompt
        can be mocked in tests.
    #>
    [cmdletbinding()]
    Param()

    [Console]::ReadLine()
}
