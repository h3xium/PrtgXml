---
external help file: PrtgXml-help.xml
Module Name: PrtgXml
online version: https://github.com/lordmilko/PrtgXml/blob/master/docs/LimitMaxWarning.md
schema: 2.0.0
---

# LimitMaxWarning

## SYNOPSIS

Generates a \<LimitMaxWarning\>\</LimitMaxWarning\> XML tag for specifying the default upper warning limit threshold of a channel in a custom PRTG Network Monitor EXE/XML Sensor.

## SYNTAX

```
LimitMaxWarning [[-Value] <String>] [<CommonParameters>]
```

## DESCRIPTION

The LimitMaxWarning tag specifies the maximum value a channel's value must stay below to avoid going into a warning state.
A sensor will enter a warning state when a channel's value goes above this threshold.

If LimitMode is not set to 1 when this channel is created, this value will not take effect until limits are manually enabled in the PRTG UI.

This tag can be used in conjunction with LimitMinWarning and LimitWarningMsg.

This tag will only be considered when the channel is initially created. Once created, the lower warning limit can be adjusted under the channel's settings.

## EXAMPLES

### EXAMPLE 1

```powershell
Prtg {
    Result {
        Channel "My channel"
        Value 3
        LimitMode 1
        LimitMaxWarning 4
    }
}
```

Specify an upper warning limit for a channel.

## PARAMETERS

### -Value
The value to use.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## RELATED LINKS

[Prtg](Prtg.md)

[Result](Result.md)

[LimitMode](LimitMode.md)

[LimitMinWarning](LimitMinWarning.md)

[LimitWarningMsg](LimitWarningMsg.md)

[LimitMinError](LimitMinError.md)

[LimitMaxError](LimitMaxError.md)

[LimitErrorMsg](LimitErrorMsg.md)