# inventor_dotfiles
Customized files for HSMWorks and InventorHSM, that others may find useful. Files shipped as-is with no warranty or guarantee.

## Posts
Files for the post processor. Some are machine customizations, others are for generating work documentation.

### Fanuc/fanuc with subprograms and vise.cps
* Basic vise rotation (via G68/G69) for double-lock style vises like the Kurt HDL6J. 
* Designed for when seperate work-offsets are used to reference each jaw.
* Rotation angle is customizable for odd setups.
* Adds basic A/B pallet changer actions.
  * **Note:** Consult your machine tool's manual and adjust the M-codes in the file according to your machine.
  * ```pallet-next```: Swap to next immediate pallet
  * ```pallet-a```: Swap to pallet A
  * ```pallet-b```: Swap to pallet B
  
### Setup/tool-list.cps
* Mustache.js for generating setup documentation.
* Work in progress, will be cleaner.
* Increases flexability of the setup document generatror.
