local DefaultLevels = { default = 'Damaged' }

BodyParts = {
    ['0'] = { id = 'hip', label = 'Damaged Hipbone', levels = { default = 'Damaged', ['10'] = 'Damaged x2', ['20'] = 'Damaged x3', ['30'] = 'Damaged x3', ['40'] = 'Damaged x3' } },
    ['10706'] = { id = 'rclavicle', label = 'Right Clavicle', levels = DefaultLevels },
    ['64729'] = { id = 'lclavicle', label = 'Left Clavicle', levels = DefaultLevels },
    ['14201'] = { id = 'lfoot', label = 'Left Foot', levels = DefaultLevels },
    ['18905'] = { id = 'lhand', label = 'Left Hand', levels = DefaultLevels },
    ['24816'] = { id = 'lbdy', label = 'Lower Chest', levels = DefaultLevels },
    ['24817'] = { id = 'ubdy', label = 'Upper Chest', levels = DefaultLevels },
    ['24818'] = { id = 'shoulder', label = 'Shoulder', levels = DefaultLevels },
    ['28252'] = { id = 'rforearm', label = 'Right Forearm', levels = DefaultLevels },
    ['36864'] = { id = 'rleg', label = 'Right Leg', levels = DefaultLevels },
    ['39317'] = { id = 'neck', label = 'Neck', levels = DefaultLevels },
    ['40269'] = { id = 'ruparm', label = 'Right Upper Arm', levels = DefaultLevels },
    ['45509'] = { id = 'luparm', label = 'Left Upper Arm', levels = DefaultLevels },
    ['51826'] = { id = 'rthigh', label = 'Right Thigh', levels = DefaultLevels },
    ['52301'] = { id = 'rfoot', label = 'Right Foot', levels = DefaultLevels },
    ['57005'] = { id = 'rhand', label = 'Right Hand', levels = DefaultLevels },
    ['57597'] = { id = '5lumbar', label = '5th Lumbar Vertebra', levels = DefaultLevels },
    ['58271'] = { id = 'lthigh', label = 'Left Thigh', levels = DefaultLevels },
    ['61163'] = { id = 'lforearm', label = 'Left Forearm', levels = DefaultLevels },
    ['63931'] = { id = 'lleg', label = 'Left Leg', levels = DefaultLevels },
    ['31086'] = { id = 'head', label = 'Head', levels = DefaultLevels },
}

BodyPartsById = {}

for _, part in pairs(BodyParts) do
    BodyPartsById[part.id] = part
end
