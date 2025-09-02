
List<Map<String, dynamic>> vehicleList = [
  {
    'image': 'l300.jpg',
    'place': 'Open Space',
    'name': 'L 300',
    'destination': 'CGH',
    'price': 25,
    'time': '11:00 AM',
    'date': '09/18/2024',
    'deliver': [
      {
        'from': {'code': "MDMPI", 'name': "MDMPI"},
        'to': {'code': "CGH", 'name': "CGH"},
        'flying_time': '5H 20M',
        'date': "9 MAY",
        'departure_time': "10:00 AM",
        "number": 23,
        'items': [
          {
            'item': 'DxC AU 700',
            'serial': 'AU002123',
            'qty': '1',
            'unit': 'unit'
          },
        ]
      },
      {
        'from': {'code': "MDMPI", 'name': "SLMC QC"},
        'to': {'code': "SLMC QC", 'name': "SLMC QC"},
        'flying_time': '4H 20M',
        'date': "1 MAY",
        'departure_time': "09:00 AM",
        "number": 45,
        'items': [
          {'item': 'Reagent', 'serial': '123456', 'qty': '6', 'unit': 'box'},
        ]
      },
    ]
  },
  {
    'image': 'hilux.jpg',
    'place': 'Tallest Building',
    'name': 'Hilux',
    'destination': 'SLMC QC',
    'price': 68,
    'time': '01:00 AM',
    'date': '09/18/2024',
    'deliver': [
      {
        'from': {'code': "MDMPI", 'name': "MDMPI"},
        'to': {'code': "SH", 'name': "LCP"},
        'flying_time': '4H 20M',
        'date': "10 MAY",
        'departure_time': "09:00 AM",
        "number": 45,
        'items': [
          {'item': 'Reagent', 'serial': '123456', 'qty': '6', 'unit': 'box'},
        ]
      },
    ]
  },
  {
    'image': 'motor.jpeg',
    'place': 'Global Will',
    'name': 'Nmax',
    'destination': 'LCP',
    'price': 40,
    'time': '10:00 AM',
    'date': '09/18/2024',
    'deliver': [
      {
        'from': {'code': "MDMPI", 'name': "CGH"},
        'to': {'code': "MDMPI", 'name': "CGH"},
        'flying_time': '8H 30M',
        'date': "1 MAY",
        'departure_time': "08:00 AM",
        "number": 23,
        'items': [
          {'item': 'Control', 'serial': '123456', 'qty': '5', 'unit': 'box'},
          {'item': 'Reagent', 'serial': '123456', 'qty': '6', 'unit': 'box'},
        ]
      },
    ]
  },
  {
    'image': 'urban.jpg',
    'place': 'Available',
    'name': 'Urban Van',
    'destination': 'None',
    'price': 0,
    'time': 'None',
    'date': 'None',
    'deliver': []
  },
  {
    'image': 'urban.jpg',
    'place': 'Available',
    'name': 'Angkas',
    'destination': 'None',
    'price': 0,
    'time': 'None',
    'date': 'None',
    'deliver': []
  },
  {
    'image': 'urban.jpg',
    'place': 'Available',
    'name': 'Move It',
    'destination': 'None',
    'price': 0,
    'time': 'None',
    'date': 'None',
    'deliver': []
  },
];
List<Map<String, dynamic>> deliveryList = [
  {
    'from': {'code': "MDMPI", 'name': "MDMPI"},
    'to': {'code': "CGH", 'name': "CGH"},
    'flying_time': '5H 20M',
    'date': "9 MAY",
    'departure_time': "10:00 AM",
    "number": 23,
    'items': [
      {'item': 'DxC AU 700', 'serial': 'AU002123', 'qty': '1', 'unit': 'unit'},
    ]
  },
  {
    'from': {'code': "MDMPI", 'name': "SLMC QC"},
    'to': {'code': "SLMC QC", 'name': "SLMC QC"},
    'flying_time': '4H 20M',
    'date': "1 MAY",
    'departure_time': "09:00 AM",
    "number": 45,
    'items': [
      {'item': 'Reagent', 'serial': '123456', 'qty': '6', 'unit': 'box'},
    ]
  },
  {
    'from': {'code': "MDMPI", 'name': "SLMC QC"},
    'to': {'code': "SH", 'name': "Shanghai"},
    'flying_time': '4H 20M',
    'date': "10 MAY",
    'departure_time': "09:00 AM",
    "number": 45,
    'items': [
      {'item': 'Reagent', 'serial': '123456', 'qty': '6', 'unit': 'box'},
    ]
  },
  {
    'from': {'code': "MDMPI", 'name': "CGH"},
    'to': {'code': "MDMPI", 'name': "CGH"},
    'flying_time': '8H 30M',
    'date': "1 MAY",
    'departure_time': "08:00 AM",
    "number": 23,
    'items': [
      {'item': 'Control', 'serial': '123456', 'qty': '5', 'unit': 'box'},
      {'item': 'Reagent', 'serial': '123456', 'qty': '6', 'unit': 'box'},
    ]
  },
];
List<Map<String, dynamic>> itemList = [
  {'item': 'Control', 'serial': '123456', 'qty': '5', 'unit': 'box'},
  {'item': 'DXH 900', 'serial': 'DXH8899123', 'qty': '1', 'unit': 'unit'},
  {'item': 'DxC AU 700', 'serial': 'AU002123', 'qty': '1', 'unit': 'unit'},
  {'item': 'Reagent', 'serial': '123456', 'qty': '6', 'unit': 'box'},
];
List<Map<String, dynamic>> vehicleOnGoingList = [
  {
    'image': 'l300.jpg',
    'place': 'Open Space',
    'name': 'L 300',
    'destination': 'CGH',
    'price': 25,
    'time': '11:00 AM',
    'date': '09/18/2024',
    'deliver': [
      {
        'from': {'code': "MDMPI", 'name': "MDMPI"},
        'to': {'code': "CGH", 'name': "CGH"},
        'flying_time': '5H 20M',
        'date': "9 MAY",
        'departure_time': "10:00 AM",
        "number": 23,
        'items': [
          {
            'item': 'DxC AU 700',
            'serial': 'AU002123',
            'qty': '1',
            'unit': 'unit'
          },
        ]
      },
      {
        'from': {'code': "MDMPI", 'name': "SLMC QC"},
        'to': {'code': "SLMC QC", 'name': "SLMC QC"},
        'flying_time': '4H 20M',
        'date': "1 MAY",
        'departure_time': "09:00 AM",
        "number": 45,
        'items': [
          {'item': 'Reagent', 'serial': '123456', 'qty': '6', 'unit': 'box'},
        ]
      },
    ]
  },
  {
    'image': 'hilux.jpg',
    'place': 'Tallest Building',
    'name': 'Hilux',
    'destination': 'SLMC QC',
    'price': 68,
    'time': '01:00 AM',
    'date': '09/18/2024',
    'deliver': [
      {
        'from': {'code': "MDMPI", 'name': "MDMPI"},
        'to': {'code': "SH", 'name': "LCP"},
        'flying_time': '4H 20M',
        'date': "10 MAY",
        'departure_time': "09:00 AM",
        "number": 45,
        'items': [
          {'item': 'Reagent', 'serial': '123456', 'qty': '6', 'unit': 'box'},
        ]
      },
    ]
  },
  {
    'image': 'motor.jpeg',
    'place': 'Global Will',
    'name': 'Nmax',
    'destination': 'LCP',
    'price': 40,
    'time': '10:00 AM',
    'date': '09/18/2024',
    'deliver': [
      {
        'from': {'code': "MDMPI", 'name': "CGH"},
        'to': {'code': "MDMPI", 'name': "CGH"},
        'flying_time': '8H 30M',
        'date': "1 MAY",
        'departure_time': "08:00 AM",
        "number": 23,
        'items': [
          {'item': 'Control', 'serial': '123456', 'qty': '5', 'unit': 'box'},
          {'item': 'Reagent', 'serial': '123456', 'qty': '6', 'unit': 'box'},
        ]
      },
    ]
  },
];
List<Map<String, dynamic>> itemListStock = [
  {
    "id": 1,
    "name": "Laptop",
    "description": "A high-performance laptop suitable for gaming and work.",
    "serial_number": "SN123456",
    "count": 0,
    "unit": "pcs"
  },
  {
    "id": 2,
    "name": "Smartphone",
    "description": "A latest model smartphone with a powerful camera.",
    "serial_number": "SN123457",
    "count": 0,
    "unit": "pcs"
  },
  {
    "id": 3,
    "name": "Headphones",
    "description": "Noise-cancelling over-ear headphones.",
    "serial_number": "SN123458",
    "count": 0,
    "unit": "pcs"
  },
  {
    "id": 4,
    "name": "Smartwatch",
    "description": "A smartwatch with fitness tracking features.",
    "serial_number": "SN123459",
    "count": 0,
    "unit": "pcs"
  },
  {
    "id": 5,
    "name": "Tablet",
    "description": "A lightweight tablet with a 10-inch display.",
    "serial_number": "SN123460",
    "count": 0,
    "unit": "pcs"
  },
  {
    "id": 6,
    "name": "Camera",
    "description": "A digital camera with 4K video recording.",
    "serial_number": "SN123461",
    "count": 0,
    "unit": "pcs"
  },
  {
    "id": 7,
    "name": "Printer",
    "description": "A wireless printer with scanning and copying functions.",
    "serial_number": "SN123462",
    "count": 0,
    "unit": "pcs"
  },
  {
    "id": 8,
    "name": "Monitor",
    "description": "A 27-inch 4K UHD monitor.",
    "serial_number": "SN123463",
    "count": 0,
    "unit": "pcs"
  },
  {
    "id": 9,
    "name": "Keyboard",
    "description": "A mechanical keyboard with RGB lighting.",
    "serial_number": "SN123464",
    "count": 0,
    "unit": "pcs"
  },
  {
    "id": 10,
    "name": "Mouse",
    "description": "A wireless ergonomic mouse.",
    "serial_number": "SN123465",
    "count": 0,
    "unit": "pcs"
  }
];
