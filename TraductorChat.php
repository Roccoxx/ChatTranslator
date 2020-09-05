<?php 
$sl = $_GET['sl'];
$tl = $_GET['tl'];
$text = $_GET['text'];

$text = str_replace(' ', '%20', $text);

$url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=$sl&tl=$tl&dt=t&q=$text";

$contents = file_get_contents($url);
if(!$contents)
{
    die("Esa es una yaga");
}
$contents = utf8_encode($contents);

$data=json_decode($contents);

$result=$data[0][0][0];

if(strcasecmp($tl, 'de') == 0)
{
	// German
	$result = str_replace('Ä', 'Ae', $result);
	$result = str_replace('ä', 'ae', $result);
	$result = str_replace('Ö', 'Oe', $result);
	$result = str_replace('ö', 'oe', $result);
	$result = str_replace('Ü', 'Ue', $result);
	$result = str_replace('ü', 'ue', $result);
	$result = str_replace('ß', 'ss', $result);
}
else if(strcasecmp($tl, 'tr') == 0)
{
	// Turkish
	$result = str_replace('Ö', 'O', $result);
	$result = str_replace('ö', 'o', $result);
	$result = str_replace('Ü', 'U', $result);
	$result = str_replace('ü', 'u', $result);
	$result = str_replace('Ç', 'C', $result);
	$result = str_replace('ç', 'c', $result);
	$result = str_replace('ý', 'y', $result);
	$result = str_replace('þ', 'p', $result);
}
else if(strcasecmp($tl, 'fr') == 0)
{
	// French
	$result = str_replace('à', 'a', $result);
	$result = str_replace('è', 'e', $result);
	$result = str_replace('ô', 'o', $result);
	$result = str_replace('ù', 'u', $result);
	$result = str_replace('Ç', 'C', $result);
	$result = str_replace('Œ', 'CE', $result);
	$result = str_replace('â', 'a', $result);
	$result = str_replace('ê', 'e', $result);
	$result = str_replace('î', 'i', $result);
	$result = str_replace('û', 'u', $result);
	$result = str_replace('é', 'e', $result);
	$result = str_replace('ë', 'e', $result);
	$result = str_replace('ï', 'i', $result);
	$result = str_replace('ç', 'c', $result);
}
else if(strcasecmp($tl, 'sv') == 0)
{
	// Swedish
	$result = str_replace('ö', 'o', $result);
	$result = str_replace('å', 'a', $result);
	$result = str_replace('ä', 'a', $result);
	$result = str_replace('Ö', 'O', $result);
	$result = str_replace('Å', 'A', $result);
	$result = str_replace('Ä', 'A', $result);
}
else if(strcasecmp($tl, 'da') == 0)
{
	// Danish
	$result = str_replace('å', 'aa', $result);
	$result = str_replace('ø', 'o', $result);
	$result = str_replace('æ', 'ae', $result);
	$result = str_replace('Å', 'Aa', $result);
	$result = str_replace('Æ', 'Ae', $result);
	$result = str_replace('Ø', 'Oe', $result);
}
else if(strcasecmp($tl, 'nl') == 0)
{
	// Dutch
	$result = str_replace('ë', 'e', $result);
	$result = str_replace('ï', 'i', $result);
}
else if(strcasecmp($tl, 'es') == 0)
{
	$result = utf8_decode($result);
}
else if(strcasecmp($tl, 'fi') == 0)
{
	// Finnish
	$result = str_replace('Ä', 'A', $result);
	$result = str_replace('Ö', 'O', $result);
	$result = str_replace('ä', 'a', $result);
	$result = str_replace('ö', 'o', $result);
}
else if(strcasecmp($tl, 'bg') == 0)
{
	// Bulgarian
	$replace_chars = Array(
		'b0'=>'A', // А-A
		'd0'=>'a', // а-a
		'b1'=>'B', // Б-B
		'd1'=>'b', // б-b
		'b2'=>'V', // В-V
		'd2'=>'v', // в-v
		'b3'=>'G', // Г-G
		'd3'=>'g', // г-g
		'b4'=>'D', // Д-D
		'd4'=>'d', // д-d
		'b5'=>'E', // Е-E
		'd5'=>'e', // е-e
		'b6'=>'Zh', // Ж-Zh
		'd6'=>'zh', // ж-zh
		'b7'=>'Z', // З-Z
		'd7'=>'z', // з-z
		'b8'=>'I', // И-I
		'd8'=>'i', // и-i
		'b9'=>'Y', // Й-Y
		'd9'=>'y', // й-y
		'ba'=>'K', // К-K
		'da'=>'k', // к-k
		'bb'=>'L', // Л-L
		'db'=>'l', // л-l
		'bc'=>'M', // М-M
		'dc'=>'m', // м-m
		'bd'=>'N', // Н-N
		'dd'=>'n', // н-n
		'be'=>'O', // О-O
		'de'=>'o', // о-o
		'bf'=>'P', // П-P
		'df'=>'p', // п-p
		'c0'=>'R', // Р-R
		'e0'=>'r', // р-r
		'c1'=>'S', // С-S
		'e1'=>'s', // с-s
		'c2'=>'T', // Т-T
		'e2'=>'t', // т-t
		'c3'=>'U', // У-U
		'e3'=>'u', // у-u
		'c4'=>'F', // Ф-F
		'e4'=>'f', // ф-f
		'c5'=>'H', // Х-H
		'e5'=>'h', // х-h
		'c6'=>'Ts', // Ц-Ts
		'e6'=>'ts', // ц-ts
		'c7'=>'Ch', // Ч-Ch
		'e7'=>'ch', // ч-ch
		'c8'=>'Sh', // Ш-Sh
		'e8'=>'sh', // ш-sh
		'c9'=>'Sht', // Щ-Sht
		'd9'=>'sht', // щ-sht
		'da'=>'A', // Ъ-A
		'ea'=>'a', // ъ-a
		'dc'=>'Y', // Ь-Y
		'ec'=>'y', // ь-y
		'de'=>'Yu', // Ю-Yu
		'ee'=>'yu', // ю-yu
		'df'=>'Ya', // Я-Ya
		'ef'=>'ya' // я-ya
	);
	
	$result = strToHex($result);
	$result = strtr($result, $replace_chars);
	$result = hexToEnglish($result);
}
else if(strcasecmp($tl, 'ro') == 0)
{
	// Romanian
	$result = str_replace('A', 'A', $result);
	$result = str_replace('Î', 'I', $result);
	$result = str_replace('S', 'S', $result);
	$result = str_replace('T', 'T', $result);
	$result = str_replace('Â', 'A', $result);
	$result = str_replace('a', 'a', $result);
	$result = str_replace('î', 'i', $result);
	$result = str_replace('s', 's', $result);
	$result = str_replace('t', 't', $result);
	$result = str_replace('â', 'a', $result);
}
else if(strcasecmp($tl, 'lt') == 0)
{
	// Lithuania
	$result = str_replace('Ą', 'A', $result);
	$result = str_replace('ą', 'a', $result);
	$result = str_replace('Č', 'C', $result);
	$result = str_replace('č', 'c', $result);
	$result = str_replace('Ę', 'E', $result);
	$result = str_replace('ę', 'e', $result);
	$result = str_replace('Ė', 'E', $result);
	$result = str_replace('ė', 'e', $result);
	$result = str_replace('Į', 'I', $result);
	$result = str_replace('į', 'i', $result);
	$result = str_replace('Š', 'S', $result);
	$result = str_replace('š', 's', $result);
	$result = str_replace('Ų', 'U', $result);
	$result = str_replace('ų', 'u', $result);
	$result = str_replace('Ū', 'U', $result);
	$result = str_replace('ū', 'u', $result);
	$result = str_replace('Ž', 'Z', $result);
	$result = str_replace('ž', 'z', $result);
}

/* Functions start */
	function strToHex($string)
	{
		$hex='';
		for($i=0; $i<strlen($string); $i++)
		{
			if($string[$i] == ' ' || $string[$i] == ',' || $string[$i] == '?' || $string[$i] == '!' || $string[$i] == '.')
			{
				$hex .= $string[$i];
				continue;
			}
			$hex .= dechex(ord($string[$i]))."|";
		}
		return $hex;
	}
	
	function hexToEnglish($string)
	{
		$replace_chars = Array(
			'41'=>'A',
			'61'=>'a',
			'42'=>'B',
			'62'=>'b',
			'43'=>'C',
			'63'=>'c',
			'44'=>'D',
			'64'=>'d',
			'45'=>'E',
			'65'=>'e',
			'46'=>'F',
			'66'=>'f',
			'47'=>'G',
			'67'=>'g',
			'48'=>'H',
			'68'=>'h',
			'49'=>'I',
			'69'=>'i',
			'4a'=>'J',
			'6a'=>'j',
			'4b'=>'K',
			'6b'=>'k',
			'4c'=>'L',
			'6c'=>'l',
			'4d'=>'M',
			'6d'=>'m',
			'4e'=>'N',
			'6e'=>'n',
			'4f'=>'O',
			'6f'=>'o',
			'50'=>'P',
			'70'=>'p',
			'51'=>'Q',
			'71'=>'q',
			'52'=>'R',
			'72'=>'r',
			'53'=>'S',
			'73'=>'s',
			'74'=>'T',
			'74'=>'t',
			'75'=>'U',
			'75'=>'u',
			'76'=>'V',
			'76'=>'v',
			'77'=>'W',
			'77'=>'w',
			'78'=>'X',
			'78'=>'x',
			'79'=>'Y',
			'79'=>'y',
			'5a'=>'Z',
			'7a'=>'z',
			'|'=>''
		);
		
		$string = strtr($string, $replace_chars);
		return $string;
	}

echo $result;
?>