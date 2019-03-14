param(
    [string]$MediaXmlFile="C:\Data\OneDrive - Microsoft\data\IP\Blogs\paulomarques.wordpress.media.2019-02-28.xml",
    [string]$PrefixToSuppress="https://blogs.technet.microsoft.com/paulomarques/",
    [string]$mediafolder="C:\Data\OneDrive - Microsoft\data\IP\Blogs\media"
)

$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

mkdir $mediafolder -ErrorAction SilentlyContinue

[xml]$xml = get-content $mediaXmlFile

$objects = @()

foreach ($item in $xml.rss.channel.item)
{
    if ((-not $item.guid."#text".Contains("uploads")) `
        -and (-not $item.guid."#text".Contains("thumb") `
        -and (-not $item.link.Contains("wlemoticon") `
        -and (-not $item.link.Contains("attachment") `
        -and (-not $item.link.Contains("azure-rm-storage-tables-powershell-module-now-includes-support-for-cosmos-db-tables"))))))
    {
        Write-Host "Getting info from: $($item.link)"
        $webobj = Invoke-WebRequest -Uri $($item.link)
        $webobj.RawContent | out-file "./$($item.title).html"
        $webtext = get-content "./$($item.title).html"
        [xml]$blobxml = $webtext | Where-Object { $_.contains("blob.core.windows.net/media") }

        $DestFolderName = $item.link.Replace($PrefixToSuppress,$null).Replace($item.title.Replace(".","-"),"").replace("-2/",$null).replace("//",$null).Replace("/","-")
        $objects += New-Object -TypeName psobject -Property @{"FileName"=$item.title; "PageUrl"=$item.link; "DestFolder"= $DestFolderName; "BlobURI"=$blobxml.p.a.href}
    }
}

$WebClient = new-object System.Net.WebClient

foreach ($item in $objects)
{
    $DestFolderFullPath = (Join-Path $mediafolder $item.DestFolder)
    if (-not (Test-Path $DestFolderFullPath))
    {
        mkdir $DestFolderFullPath
    }

    $WebClient.DownloadFile($item.BlobUri,(Join-Path $DestFolderFullPath $item.FileName))

}

remove-item -path "./*.html"
