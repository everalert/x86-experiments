# x86 experiments

Just messing around implementing different things in x86 assembly. I mean, how hard could it be? ¯\\\_(ツ)_/¯

## Requirements

Depending on the sub-project, NASM and Golink or LLD-Link. I assume (non-LLD) Link.exe will also work, but have not tested. I also assume the specific versions don't matter too much, but for reference the following were used:
```
NASM version 3.01 compiled on Oct 10 2025
```
```
GoLink.Exe Version 1.0.4.6
```
```
LLD 12.0.0
```

## Usage

Build and run with either of the following:

```batch
./b /BUILD /###
./b /RUN /###
```
```batch
:: build and run in one step
./b /BUILD /RUN /###
```
```batch
cd <project>
./build
./run
```

## License

MIT License. See [LICENSE](LICENSE)
