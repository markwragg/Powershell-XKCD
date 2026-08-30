function ConvertTo-XKCDTerminalImage {
    <#
    .SYNOPSIS
        Converts raw image bytes into the inline graphics escape sequence for the specified (or detected)
        terminal graphics protocol -- Kitty, iTerm2, or Sixel.
    #>
    [cmdletbinding()]
    Param(
        # The raw bytes of the image to convert (e.g. PNG or JPEG).
        [Parameter(Mandatory)]
        [byte[]]
        $ImageBytes,

        # The terminal graphics protocol to encode for. By default this is whichever protocol is detected for
        # the current terminal.
        [ValidateSet('Kitty', 'iTerm2', 'Sixel')]
        [string]
        $Protocol = (Get-XKCDTerminalGraphicsProtocol)
    )

    $esc = [char]27

    switch ($Protocol) {
        'Kitty' {
            $base64 = [Convert]::ToBase64String($ImageBytes)
            $chunkSize = 4096
            $sb = [System.Text.StringBuilder]::new()

            for ($offset = 0; $offset -lt $base64.Length; $offset += $chunkSize) {
                $chunk = $base64.Substring($offset, [Math]::Min($chunkSize, $base64.Length - $offset))
                $more = if (($offset + $chunkSize) -lt $base64.Length) { 1 } else { 0 }
                $control = if ($offset -eq 0) { "a=T,f=100,m=$more" } else { "m=$more" }

                [void]$sb.Append("$esc" + "_G$control;$chunk" + "$esc" + '\')
            }

            $sb.ToString()
        }
        'iTerm2' {
            $base64 = [Convert]::ToBase64String($ImageBytes)
            $bel = [char]7

            "$esc]1337;File=inline=1;size=$($ImageBytes.Length):$base64$bel"
        }
        'Sixel' {
            ConvertTo-XKCDSixel -ImageBytes $ImageBytes
        }
        default {
            throw 'Your terminal does not appear to support inline image display (Sixel, Kitty, or iTerm2 graphics protocols).'
        }
    }
}
