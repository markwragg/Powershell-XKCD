function Add-XKCDHtmlProperty {
    <#
    .SYNOPSIS
        Adds 'html_img' and 'html' script properties to a comic object, used by both Get-XKCD and Find-XKCD.

    .DESCRIPTION
        Both properties lazily build their HTML from the comic's own 'num', 'img' and 'alt' properties, so they
        stay correct even if a comic object is modified afterwards, and there's no HTML string to keep in sync
        in XKCD.json. Named lowercase to match the casing of the comic's other properties (num, img, alt,
        safe_title, etc.), all of which come straight from the xkcd API's JSON.

        'html_img' is just the <img> tag, for embedding the comic image without linking it anywhere. 'html' wraps
        that same tag in a link to the comic's page on xkcd.com.
    #>
    [CmdletBinding()]
    Param(
        # The comic object to add the properties to.
        [Parameter(Mandatory, ValueFromPipeline)]
        [psobject]
        $Comic
    )

    Process {
        Add-Member -InputObject $Comic -MemberType ScriptProperty -Name 'html_img' -Value {
            $AltText = [System.Net.WebUtility]::HtmlEncode($this.alt)
            "<img src=`"$($this.img)`" alt=`"$AltText`" title=`"$AltText`">"
        }

        Add-Member -InputObject $Comic -MemberType ScriptProperty -Name 'html' -Value {
            "<a href=`"https://xkcd.com/$($this.num)`">$($this.html_img)</a>"
        } -PassThru
    }
}
