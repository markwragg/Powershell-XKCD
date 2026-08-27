Function Show-XKCDImage {
    <#
    .SYNOPSIS
        Writes an image to the console using whichever inline graphics protocol the terminal supports
        (Kitty, iTerm2, or Sixel). Does nothing but warn if none are detected.
    #>
    [cmdletbinding()]
    Param(
        # The raw bytes of the image to display (e.g. PNG or JPEG).
        [Parameter(Mandatory)]
        [byte[]]
        $ImageBytes
    )

    $esc = [char]27
    $protocol = Get-XKCDTerminalGraphicsProtocol

    switch ($protocol) {
        'Kitty' {
            $base64 = [Convert]::ToBase64String($ImageBytes)
            $chunkSize = 4096

            for ($offset = 0; $offset -lt $base64.Length; $offset += $chunkSize) {
                $chunk = $base64.Substring($offset, [Math]::Min($chunkSize, $base64.Length - $offset))
                $more = if (($offset + $chunkSize) -lt $base64.Length) { 1 } else { 0 }
                $control = if ($offset -eq 0) { "a=T,f=100,m=$more" } else { "m=$more" }

                [Console]::Out.Write("$esc" + "_G$control;$chunk" + "$esc" + '\')
            }
        }
        'iTerm2' {
            $base64 = [Convert]::ToBase64String($ImageBytes)
            $bel = [char]7

            [Console]::Out.Write("$esc]1337;File=inline=1;size=$($ImageBytes.Length):$base64$bel")
        }
        'Sixel' {
            try {
                [Console]::Out.Write((ConvertTo-XKCDSixel -ImageBytes $ImageBytes))
            }
            catch {
                Write-Warning "Unable to render the comic as Sixel: $_"
                return
            }
        }
        default {
            Write-Warning 'Your terminal does not appear to support inline image display (Sixel, Kitty, or iTerm2 graphics protocols), so the comic could not be shown.'
            return
        }
    }

    [Console]::Out.Write([Environment]::NewLine)
}
