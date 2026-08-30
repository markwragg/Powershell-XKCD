function Import-XKCDTerminalImage {
    <#
    .SYNOPSIS
        Redisplays a comic's image from a file previously saved with Export-XKCDTerminalImage.

    .DESCRIPTION
        The Import-XKCDTerminalImage cmdlet reads a file saved by Export-XKCDTerminalImage and writes its saved
        terminal graphics escape sequence straight to the console, without needing network access or having to
        regenerate the image data again.

        The saved file records which inline graphics protocol (Sixel, Kitty, or iTerm2) it was rendered for.
        Import-XKCDTerminalImage warns you if that doesn't match the protocol detected for the terminal you're
        importing it into, since the image may not display correctly in that case.

    .EXAMPLE
        Import-XKCDTerminalImage -Path .\2000.xkcdterm.json

        Displays the terminal image previously saved to '.\2000.xkcdterm.json'.

    .EXAMPLE
        Get-ChildItem C:\XKCD\*.xkcdterm.json | Import-XKCDTerminalImage

        Displays every terminal image saved in C:\XKCD.

    .EXAMPLE
        Export-XKCDTerminalImage -Num 353 -PassThru | Import-XKCDTerminalImage

        Exports comic number 353 and immediately redisplays it from the saved file.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding()]
    Param(
        # Path to one or more files previously saved with Export-XKCDTerminalImage. Accepts array and pipeline
        # input, including FileInfo objects (e.g. from Get-ChildItem or Export-XKCDTerminalImage -PassThru).
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('FullName')]
        [string[]]
        $Path
    )

    Process {
        $Path | ForEach-Object {
            $Saved = Get-XKCDTerminalImageFile -Path $_
            if (-not $Saved) { return }

            [Console]::Out.Write($Saved.Image)
            [Console]::Out.Write([Environment]::NewLine)
        }
    }
}
