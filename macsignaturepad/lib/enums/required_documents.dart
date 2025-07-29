enum RequiredDocument {
  photoID('Lichtbildausweis'),
  bankCard('Bankomatkarte'),
  registration('Zulassungsschein'),
  drivingLicense('Führerschein');

  final String germanName;

  const RequiredDocument(this.germanName);
}