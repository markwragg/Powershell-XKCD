function Add-XKCDHtmlProperty {
    <#
    .SYNOPSIS
        Adds 'date', 'html_img' and 'html' script properties to a comic object, used by both Get-XKCD and Find-XKCD.

    .DESCRIPTION
        All three properties are computed lazily from the comic's own 'day', 'month', 'year', 'num', 'img' and
        'alt' properties, so they stay correct even if a comic object is modified afterwards, and there's nothing
        to keep in sync in XKCD.json. Named lowercase to match the casing of the comic's other properties (num,
        img, alt, safe_title, etc.), all of which come straight from the xkcd API's JSON.

        'date' is a [datetime] built from 'day'/'month'/'year', so results can be sorted or filtered by date
        (e.g. `Get-XKCD -Newest 20 | Where-Object date -gt (Get-Date).AddDays(-30)`) without having to combine
        those three properties by hand.

        'html_img' is just the <img> tag, for embedding the comic image without linking it anywhere. 'html' wraps
        that same tag in a link to the comic's page on xkcd.com.

        Also tags the object with the 'XKCD.Comic' type name, so it picks up the table/list views defined in
        xkcd.Format.ps1xml instead of PowerShell's default formatting. -TypeName layers on an additional, more
        specific type name ahead of that base one -- used by Find-XKCD to tag its results 'XKCD.Comic.Search'
        so they pick up their own views (which include the 'query' column/property) instead, while still
        falling back to the base 'XKCD.Comic' views for anything not overridden.
    #>
    [CmdletBinding()]
    Param(
        # The comic object to add the properties to.
        [Parameter(Mandatory, ValueFromPipeline)]
        [psobject]
        $Comic,

        # An additional, more specific type name to tag the object with, inserted ahead of the base
        # 'XKCD.Comic' type name so PowerShell tries it first when selecting a format view.
        [string]
        $TypeName
    )

    Process {
        $Comic.PSObject.TypeNames.Insert(0, 'XKCD.Comic')

        if ($TypeName) {
            $Comic.PSObject.TypeNames.Insert(0, $TypeName)
        }

        Add-Member -InputObject $Comic -MemberType ScriptProperty -Name 'date' -Value {
            [datetime]::new([int]$this.year, [int]$this.month, [int]$this.day)
        }

        Add-Member -InputObject $Comic -MemberType ScriptProperty -Name 'html_img' -Value {
            $AltText = [System.Net.WebUtility]::HtmlEncode($this.alt)
            "<img src=`"$($this.img)`" alt=`"$AltText`" title=`"$AltText`">"
        }

        Add-Member -InputObject $Comic -MemberType ScriptProperty -Name 'html' -Value {
            "<a href=`"https://xkcd.com/$($this.num)`">$($this.html_img)</a>"
        } -PassThru
    }
}
