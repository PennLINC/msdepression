import csv
import re
import os
import copy

def add_to_outputs(image, outputs):
    sub = re.search('sub-[0-9]+', path).group(0)
    ses = re.search('ses-[0-9]+', path).group(0)
    run = re.search('run-[0-9]+', path).group(0)
    image_type = os.path.basename(image).replace(".nii.gz", "")
    if sub not in outputs:
        outputs[sub] = {}
    if ses not in outputs[sub]:
        outputs[sub][ses] = {}
    if run not in outputs[sub][ses]:
        outputs[sub][ses][run] = {}
    outputs[sub][ses][run][image_type] = image
    return outputs


good_outputs = {}
with open('1yr_report_address.csv') as csvfile:
    reader = csv.reader(csvfile, quotechar='"')
    next(reader) # skip header
    for row in reader:
        path = row[0]
        rating = float(row[2])
        if rating >= 75 and ('t1_n4_reg_brain_ws.nii.gz' in path or 'flair_n4_brain_ws.nii.gz' in path or 'mimosa_binary_mask_0.25.nii.gz' in path):
            good_outputs = add_to_outputs(path, good_outputs)

# make sure t1, flair, mask all reviewed
for sub, v in copy.deepcopy(good_outputs).items(): # copy because can't change dictionary size during iteration
    for ses, vv in v.items():
        for run, vvv in vv.items():
            if len(good_outputs[sub][ses][run]) != 3:
                del good_outputs[sub][ses][run]
            else: # then if you want to print it out
                print(sub, ses, run, good_outputs[sub][ses][run])
