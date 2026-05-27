part of '../main.dart';

// ── Offline disease information library ───────────────────────────────────
//
// All data is bundled at compile time — works with zero network access.
// Sources: WHO, Mayo Clinic, MedlinePlus (public health references).
// Lookup is case-insensitive and uses partial-name matching so that
// "Bronchial Asthma" and "asthma" both resolve to the same entry.

class DiseaseInfo {
  const DiseaseInfo({
    required this.overview,
    required this.commonSymptoms,
    this.keyFact = '',
  });

  /// Plain-English explanation of what the disease is (2–3 sentences).
  final String overview;

  /// Medically recognised symptoms for this condition.
  final List<String> commonSymptoms;

  /// One important takeaway the patient should know.
  final String keyFact;
}

class DiseaseLibrary {
  DiseaseLibrary._();

  /// Returns [DiseaseInfo] for [name], or `null` if not in the library.
  /// Matching tries exact key → contains → word-overlap, all case-insensitive.
  static DiseaseInfo? lookup(String name) {
    final String q = name.toLowerCase().trim();
    if (q.isEmpty) return null;

    // 1. Exact key match
    final DiseaseInfo? exact = _db[q];
    if (exact != null) return exact;

    // 2. Library key is a substring of query  (e.g. "gout" in "acute gout")
    for (final MapEntry<String, DiseaseInfo> e in _db.entries) {
      if (q.contains(e.key)) return e.value;
    }

    // 3. Query is a substring of library key  (e.g. "hepatitis" matches "hepatitis a")
    for (final MapEntry<String, DiseaseInfo> e in _db.entries) {
      if (e.key.contains(q)) return e.value;
    }

    // 4. Word-overlap: any significant word in query matches any word in key
    final List<String> qWords = q.split(' ')
        .where((String w) => w.length > 3)
        .toList();
    for (final MapEntry<String, DiseaseInfo> e in _db.entries) {
      for (final String w in qWords) {
        if (e.key.contains(w)) return e.value;
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Disease database
  // ──────────────────────────────────────────────────────────────────────────
  static const Map<String, DiseaseInfo> _db = <String, DiseaseInfo>{

    // ── Gastrointestinal ──────────────────────────────────────────────────

    'appendicitis': DiseaseInfo(
      overview:
          'Appendicitis is an inflammation of the appendix, a small finger-shaped pouch attached to the large intestine on the lower right side of the abdomen. It usually causes sudden, severe pain that gets worse over time. It is a medical emergency that typically requires surgery to remove the appendix.',
      commonSymptoms: [
        'Sudden pain starting around the navel, shifting to lower right abdomen',
        'Pain that worsens with movement, coughing or deep breaths',
        'Nausea and vomiting',
        'Loss of appetite',
        'Low-grade fever (37.5–38.5 °C)',
        'Abdominal bloating and rigidity',
      ],
      keyFact:
          'Without treatment, an inflamed appendix can rupture within 24–72 hours — seek emergency care immediately.',
    ),

    'gerd': DiseaseInfo(
      overview:
          'Gastroesophageal reflux disease (GERD) is a digestive disorder in which stomach acid frequently flows back into the oesophagus (the tube connecting the mouth to the stomach). This backwash (acid reflux) can irritate the lining of the oesophagus. It is a chronic condition that often improves with lifestyle changes and medication.',
      commonSymptoms: [
        'Heartburn — burning sensation in the chest, often after eating',
        'Regurgitation of food or sour liquid',
        'Difficulty swallowing (dysphagia)',
        'Sensation of a lump in the throat',
        'Chronic cough or hoarse voice',
        'Worsening symptoms when lying down or bending over',
      ],
      keyFact:
          'Eating smaller meals, avoiding lying down after eating, and raising the head of the bed can significantly reduce symptoms.',
    ),

    'esophagitis': DiseaseInfo(
      overview:
          'Esophagitis is inflammation of the oesophagus — the muscular tube that carries food from the mouth to the stomach. It can be caused by acid reflux, infection, certain medications, or allergies. The condition causes pain and difficulty swallowing and can lead to ulcers or scarring if untreated.',
      commonSymptoms: [
        'Painful or difficult swallowing',
        'Burning chest pain (heartburn)',
        'Acid regurgitation',
        'Food getting stuck in the oesophagus',
        'Nausea',
        'Upper abdominal or chest pain after eating',
      ],
      keyFact:
          'Eosinophilic esophagitis (allergic type) is increasingly common — trigger foods like dairy and wheat often need to be eliminated.',
    ),

    'peptic ulcer disease': DiseaseInfo(
      overview:
          'Peptic ulcer disease refers to open sores (ulcers) that develop on the inner lining of the stomach, upper small intestine, or oesophagus. Most are caused by the bacterium Helicobacter pylori or long-term use of anti-inflammatory drugs (NSAIDs). Ulcers can heal with antibiotics and acid-reducing medications.',
      commonSymptoms: [
        'Burning or gnawing stomach pain',
        'Pain that improves after eating or taking antacids',
        'Nausea or vomiting',
        'Bloating and belching',
        'Dark, tarry stools (sign of bleeding)',
        'Unintended weight loss',
      ],
      keyFact:
          'About 70% of peptic ulcers are caused by H. pylori infection, which is curable with a short course of antibiotics.',
    ),

    'gastroenteritis': DiseaseInfo(
      overview:
          'Gastroenteritis is an inflammation of the stomach and intestines, usually caused by a viral or bacterial infection. It is commonly called "stomach flu" (although unrelated to influenza). It is typically short-lived and resolves on its own with adequate fluid intake.',
      commonSymptoms: [
        'Watery diarrhoea',
        'Nausea and vomiting',
        'Stomach cramps and pain',
        'Fever (usually low-grade)',
        'Headache and muscle aches',
        'Dehydration — dry mouth, dizziness, reduced urination',
      ],
      keyFact:
          'Dehydration is the main danger — drink small sips of oral rehydration solution (ORS) frequently to replace lost fluids and salts.',
    ),

    'hemorrhoids': DiseaseInfo(
      overview:
          'Haemorrhoids (piles) are swollen veins in the rectum or around the anus, similar to varicose veins. They are extremely common and usually caused by straining during bowel movements, chronic constipation, or prolonged sitting. Most resolve with simple self-care measures.',
      commonSymptoms: [
        'Painless bleeding during bowel movements (bright red blood on tissue)',
        'Itching or irritation around the anus',
        'Pain or discomfort when sitting',
        'Swelling or a lump near the anus',
        'Leakage of faeces',
      ],
      keyFact:
          'Eating a high-fibre diet, drinking plenty of water, and avoiding straining dramatically reduces symptoms and recurrence.',
    ),

    'chronic cholestasis': DiseaseInfo(
      overview:
          'Cholestasis is a condition where bile cannot flow from the liver to the small intestine. This causes a build-up of bile acids in the blood. It can result from liver disease, bile duct blockages, or certain medications.',
      commonSymptoms: [
        'Intense itching (pruritus), especially at night',
        'Yellowing of skin and eyes (jaundice)',
        'Dark urine and pale stools',
        'Fatigue and loss of appetite',
        'Nausea',
        'Upper right abdominal discomfort',
      ],
      keyFact:
          'The itching from cholestasis is caused by bile salt deposits under the skin and does not respond to antihistamines.',
    ),

    // ── Infectious diseases ──────────────────────────────────────────────

    'malaria': DiseaseInfo(
      overview:
          'Malaria is a life-threatening disease caused by Plasmodium parasites transmitted through the bites of infected Anopheles mosquitoes. It is preventable and curable but can rapidly become severe without prompt treatment. It is a major public health problem in tropical regions including parts of Australia.',
      commonSymptoms: [
        'Cyclical fever, chills, and sweating (every 48–72 hours)',
        'Headache and muscle aches',
        'Fatigue and extreme tiredness',
        'Nausea, vomiting and diarrhoea',
        'Anaemia and jaundice (in severe cases)',
        'Impaired consciousness (in severe malaria)',
      ],
      keyFact:
          'Malaria symptoms can appear 10–15 days after a mosquito bite — always report recent travel history to a remote or tropical area.',
    ),

    'dengue': DiseaseInfo(
      overview:
          'Dengue is a viral infection spread by Aedes mosquitoes. It is very common in tropical and subtropical regions. Most cases are mild but can progress to severe dengue (dengue haemorrhagic fever) which can be fatal. There is no specific treatment — management focuses on supportive care and hydration.',
      commonSymptoms: [
        'Sudden high fever (39–40 °C)',
        'Severe headache, especially behind the eyes',
        'Intense muscle, joint and bone pain ("breakbone fever")',
        'Skin rash appearing 2–5 days after fever onset',
        'Nausea, vomiting',
        'Bleeding from gums or nose (warning sign of severe dengue)',
      ],
      keyFact:
          'Warning signs of severe dengue include severe abdominal pain, persistent vomiting, and bleeding — seek immediate hospital care.',
    ),

    'typhoid': DiseaseInfo(
      overview:
          'Typhoid fever is a bacterial infection caused by Salmonella typhi, spread through contaminated food or water. It is common in areas with poor sanitation. Without treatment, it can be life-threatening. Vaccination and safe food handling are the best prevention.',
      commonSymptoms: [
        'Prolonged high fever (39–40 °C) that rises gradually over days',
        'Headache, weakness, and fatigue',
        'Stomach pain and constipation (early); diarrhoea (later)',
        'Loss of appetite and weight loss',
        'Rose-coloured spots on the trunk',
        'Enlarged spleen and liver',
      ],
      keyFact:
          'Typhoid is treated with antibiotics — completing the full course is essential to prevent relapse and antibiotic resistance.',
    ),

    'chicken pox': DiseaseInfo(
      overview:
          'Chickenpox (varicella) is a highly contagious viral infection caused by the varicella-zoster virus. It causes an itchy rash with fluid-filled blisters that eventually crust over. Although usually mild in children, it can be more severe in adults and those with weakened immune systems.',
      commonSymptoms: [
        'Itchy, blister-like rash that spreads over the body',
        'Fever (usually mild to moderate)',
        'Loss of appetite and tiredness',
        'Headache',
        'Fluid-filled blisters that burst and crust within 1–2 weeks',
        'New spots appearing in crops over several days',
      ],
      keyFact:
          'Scratching the blisters can cause scarring and bacterial infection — keep nails short and use calamine lotion to relieve itching.',
    ),

    'tuberculosis': DiseaseInfo(
      overview:
          'Tuberculosis (TB) is a serious bacterial infection caused by Mycobacterium tuberculosis that primarily affects the lungs. It spreads through the air when infected people cough, sneeze, or speak. TB is curable with a 6-month course of antibiotics, but drug-resistant TB is a growing problem worldwide.',
      commonSymptoms: [
        'Persistent cough lasting 3 weeks or more',
        'Coughing up blood or bloody sputum',
        'Chest pain and breathlessness',
        'Unintentional weight loss',
        'Fatigue and weakness',
        'Night sweats and fever',
        'Swollen lymph nodes',
      ],
      keyFact:
          'TB treatment must be completed fully (6 months) even if symptoms improve — stopping early leads to drug-resistant TB.',
    ),

    'hepatitis a': DiseaseInfo(
      overview:
          'Hepatitis A is a highly contagious liver infection caused by the hepatitis A virus (HAV). It is usually spread through contaminated food or water. Unlike other forms of hepatitis, it does not cause chronic liver disease and most people recover fully within a few weeks to months.',
      commonSymptoms: [
        'Fatigue and weakness',
        'Sudden nausea, vomiting and diarrhoea',
        'Abdominal pain (especially upper right, over the liver)',
        'Yellowing of skin and eyes (jaundice)',
        'Dark urine and clay-coloured stools',
        'Low-grade fever',
        'Loss of appetite',
      ],
      keyFact:
          'There is a safe and effective vaccine against Hepatitis A — recommended for travellers to endemic areas and high-risk groups.',
    ),

    'hepatitis b': DiseaseInfo(
      overview:
          'Hepatitis B is a liver infection caused by the hepatitis B virus (HBV), spread through blood, sexual contact, or from mother to baby. It can become chronic, leading to cirrhosis or liver cancer. Effective vaccines are available and have dramatically reduced transmission rates.',
      commonSymptoms: [
        'Abdominal pain and liver tenderness',
        'Dark urine and pale stools',
        'Jaundice (yellowing of skin and eyes)',
        'Fatigue and weakness',
        'Nausea, vomiting and loss of appetite',
        'Joint pain',
        'Fever',
      ],
      keyFact:
          'Many people with chronic hepatitis B have no symptoms — regular liver function tests are important to monitor disease progression.',
    ),

    'hepatitis c': DiseaseInfo(
      overview:
          'Hepatitis C is a viral liver infection transmitted primarily through blood-to-blood contact (e.g. shared needles, unscreened blood transfusions). About 75–85% of infected people develop chronic hepatitis C. Modern antiviral treatment can cure over 95% of cases within 8–12 weeks.',
      commonSymptoms: [
        'Fatigue (often the most prominent symptom)',
        'Jaundice in acute cases',
        'Nausea and loss of appetite',
        'Muscle and joint pain',
        'Mild fever',
        'Many people have no symptoms for years (silent progression)',
      ],
      keyFact:
          'Most people with chronic Hepatitis C develop no symptoms until significant liver damage (cirrhosis) has already occurred — early testing saves lives.',
    ),

    'alcoholic hepatitis': DiseaseInfo(
      overview:
          'Alcoholic hepatitis is liver inflammation caused by heavy alcohol consumption. It can develop in people who drink heavily for years, though not all heavy drinkers develop it. Severe cases can be life-threatening and may rapidly progress to liver failure.',
      commonSymptoms: [
        'Jaundice (yellowing of skin and eyes)',
        'Abdominal pain and tenderness',
        'Nausea, vomiting and loss of appetite',
        'Fever',
        'Fatigue and weakness',
        'Abdominal swelling (ascites) in severe cases',
        'Confusion or altered mental state',
      ],
      keyFact:
          'Stopping alcohol consumption immediately is the single most important step — continued drinking significantly worsens outcomes.',
    ),

    'aids': DiseaseInfo(
      overview:
          'AIDS (Acquired Immunodeficiency Syndrome) is the most advanced stage of HIV infection. HIV attacks the immune system, making the body unable to fight infections and disease. There is no cure, but antiretroviral therapy (ART) can control the virus, prevent progression to AIDS, and allow near-normal life expectancy.',
      commonSymptoms: [
        'Recurring fever and night sweats',
        'Chronic diarrhoea',
        'Rapid weight loss',
        'Extreme fatigue and weakness',
        'Swollen lymph nodes in armpits, neck or groin',
        'Sores in the mouth, genitals or anus',
        'Pneumonia and other opportunistic infections',
      ],
      keyFact:
          'With modern antiretroviral treatment, a person living with HIV can have an almost normal lifespan and cannot sexually transmit the virus to others.',
    ),

    // ── Respiratory ────────────────────────────────────────────────────────

    'bronchial asthma': DiseaseInfo(
      overview:
          'Asthma is a chronic disease of the airways that makes breathing difficult. It causes the airways to become inflamed and narrow, producing extra mucus. Triggers include allergens, exercise, cold air, smoke, and infections. It is manageable with the right medications and by avoiding triggers.',
      commonSymptoms: [
        'Shortness of breath',
        'Chest tightness or pain',
        'Wheezing (a whistling sound when breathing out)',
        'Persistent cough, especially at night or early morning',
        'Difficulty sleeping due to breathing symptoms',
        'Worsening symptoms triggered by exercise, allergens or cold air',
      ],
      keyFact:
          'Reliever inhalers (blue/salbutamol) treat immediate symptoms — preventer inhalers (brown/corticosteroid) reduce long-term inflammation and must be used daily.',
    ),

    'pneumonia': DiseaseInfo(
      overview:
          'Pneumonia is an infection that inflames the air sacs (alveoli) in one or both lungs. The air sacs may fill with fluid or pus, causing cough with phlegm, fever, chills, and difficulty breathing. It can range from mild to life-threatening. Bacterial pneumonia is usually treated with antibiotics.',
      commonSymptoms: [
        'Cough producing phlegm or pus',
        'Fever, sweating and shaking chills',
        'Shortness of breath',
        'Sharp or stabbing chest pain that worsens with deep breathing',
        'Fatigue and low energy',
        'Confusion (especially in older adults)',
        'Nausea, vomiting or diarrhoea',
      ],
      keyFact:
          'Pneumonia is the leading infectious cause of death in children under 5 worldwide — prompt antibiotic treatment is lifesaving.',
    ),

    'common cold': DiseaseInfo(
      overview:
          'The common cold is a viral infection of the upper respiratory tract, most often caused by rhinoviruses. It is the most frequent infectious disease in humans. There is no cure — treatment focuses on relieving symptoms while the immune system clears the infection over 7–10 days.',
      commonSymptoms: [
        'Runny or stuffy nose',
        'Sore or scratchy throat',
        'Sneezing',
        'Mild body aches or headache',
        'Low-grade fever (more common in children)',
        'General feeling of being unwell (malaise)',
        'Mild cough',
      ],
      keyFact:
          'Antibiotics cannot treat the common cold — they only work on bacteria. Rest, fluids, and decongestants are the most effective management.',
    ),

    // ── Cardiovascular & circulatory ─────────────────────────────────────

    'heart attack': DiseaseInfo(
      overview:
          'A heart attack (myocardial infarction) occurs when blood flow to part of the heart is blocked, usually by a blood clot forming in a coronary artery. The blocked blood supply causes heart muscle to die. It is a medical emergency — every minute without treatment increases permanent damage.',
      commonSymptoms: [
        'Chest pain, pressure, tightness or squeezing sensation',
        'Pain radiating to the left arm, jaw, neck, back or stomach',
        'Shortness of breath',
        'Cold sweat, nausea or lightheadedness',
        'Sudden extreme fatigue',
        'Women may present with subtle symptoms — nausea, jaw pain, or fatigue without chest pain',
      ],
      keyFact:
          'Time is muscle — call emergency services immediately. Chewing 300 mg of aspirin (if not allergic) while waiting can help.',
    ),

    'hypertension': DiseaseInfo(
      overview:
          'Hypertension (high blood pressure) is a common condition where the force of blood against artery walls is persistently too high. It is called the "silent killer" because most people have no symptoms despite being at high risk of heart disease, stroke, and kidney failure. It is managed with lifestyle changes and medication.',
      commonSymptoms: [
        'Usually no symptoms (silent condition)',
        'Headache (usually at the back of the head, in the morning)',
        'Dizziness or lightheadedness',
        'Visual disturbances',
        'Nosebleeds (in severe cases)',
        'Chest pain and shortness of breath (hypertensive crisis)',
        'Fatigue',
      ],
      keyFact:
          'A blood pressure reading of 140/90 mmHg or above on two separate occasions confirms hypertension — regular monitoring is essential.',
    ),

    'varicose veins': DiseaseInfo(
      overview:
          'Varicose veins are enlarged, twisted veins visible just under the surface of the skin, most commonly in the legs. They occur when vein valves weaken and allow blood to pool. They are generally harmless but can cause discomfort and, rarely, complications such as ulcers or blood clots.',
      commonSymptoms: [
        'Bulging, rope-like veins visible under the skin',
        'Aching, heavy or throbbing sensation in legs',
        'Leg swelling, especially after prolonged standing',
        'Skin itching around the affected veins',
        'Skin discolouration or ulcers near the ankle (in severe cases)',
        'Leg cramps at night',
      ],
      keyFact:
          'Wearing compression stockings, elevating legs when resting, and regular walking can significantly relieve symptoms.',
    ),

    // ── Metabolic & endocrine ─────────────────────────────────────────────

    'diabetes': DiseaseInfo(
      overview:
          'Diabetes is a chronic condition in which the body cannot properly process blood glucose (sugar), either because it does not produce enough insulin (Type 1) or cannot use insulin effectively (Type 2). Uncontrolled diabetes damages nerves, kidneys, eyes, and blood vessels over time. It requires lifelong management.',
      commonSymptoms: [
        'Frequent urination (polyuria)',
        'Excessive thirst (polydipsia)',
        'Unexplained weight loss',
        'Extreme hunger (polyphagia)',
        'Fatigue and irritability',
        'Blurred vision',
        'Slow-healing wounds and frequent infections',
      ],
      keyFact:
          'Type 2 diabetes can often be prevented or delayed through healthy diet, regular physical activity, and maintaining a healthy body weight.',
    ),

    'hypoglycemia': DiseaseInfo(
      overview:
          'Hypoglycaemia (low blood sugar) occurs when blood glucose drops below normal levels (below 4 mmol/L). It most commonly occurs in people with diabetes who take insulin or certain oral medications. Severe hypoglycaemia can cause seizures or loss of consciousness and requires immediate treatment.',
      commonSymptoms: [
        'Shakiness, trembling and sweating',
        'Rapid heartbeat (palpitations)',
        'Hunger and nausea',
        'Dizziness and light-headedness',
        'Difficulty concentrating and confusion',
        'Pale skin',
        'Weakness and fatigue',
        'Irritability or anxiety',
      ],
      keyFact:
          'The "15-15 rule": eat 15 grams of fast-acting carbohydrates (e.g. glucose tablets or fruit juice), wait 15 minutes, then recheck blood glucose.',
    ),

    'hypothyroidism': DiseaseInfo(
      overview:
          'Hypothyroidism occurs when the thyroid gland does not produce enough thyroid hormone. Thyroid hormone regulates metabolism, heart rate, and temperature. Without enough of it, many body functions slow down. It is very treatable with daily thyroid hormone replacement medication.',
      commonSymptoms: [
        'Fatigue and sluggishness',
        'Increased sensitivity to cold',
        'Constipation',
        'Unexplained weight gain',
        'Puffy face and swollen joints',
        'Thinning hair and dry skin',
        'Slow heart rate (bradycardia)',
        'Depression',
      ],
      keyFact:
          'A simple blood test (TSH level) diagnoses hypothyroidism — once on medication, most people feel completely normal.',
    ),

    'hyperthyroidism': DiseaseInfo(
      overview:
          'Hyperthyroidism occurs when the thyroid gland produces too much thyroid hormone, speeding up the body\'s metabolism. The most common cause is Graves\' disease, an autoimmune disorder. It is treatable with medications, radioiodine therapy, or surgery.',
      commonSymptoms: [
        'Unintentional weight loss despite increased appetite',
        'Rapid or irregular heartbeat (palpitations)',
        'Nervousness, anxiety and irritability',
        'Tremor — usually a fine trembling of hands and fingers',
        'Heat intolerance and excessive sweating',
        'Frequent bowel movements or diarrhoea',
        'Enlarged thyroid gland (goitre)',
        'Sleep problems',
      ],
      keyFact:
          'Graves\' disease, the most common cause, can also cause bulging eyes (exophthalmos) due to immune attack on eye tissue.',
    ),

    // ── Musculoskeletal ───────────────────────────────────────────────────

    'gout': DiseaseInfo(
      overview:
          'Gout is a form of inflammatory arthritis that causes sudden, severe episodes of joint pain, swelling, redness, and tenderness. It is caused by high levels of uric acid in the blood that crystallise and deposit in joints. The big toe is most commonly affected, but it can affect any joint.',
      commonSymptoms: [
        'Intense joint pain, most often in the big toe',
        'Swelling, redness and warmth around the affected joint',
        'Extreme tenderness — even bedsheet contact can feel painful',
        'Limited range of motion in the affected joint',
        'Lingering joint discomfort after the acute attack',
        'Tophi (firm lumps under the skin) in chronic gout',
      ],
      keyFact:
          'Drinking plenty of water, reducing alcohol, red meat and seafood, and maintaining a healthy weight can dramatically reduce gout attacks.',
    ),

    'arthritis': DiseaseInfo(
      overview:
          'Arthritis refers to inflammation of one or more joints, causing pain, stiffness, and reduced movement. There are over 100 types; the most common are osteoarthritis (wear and tear) and rheumatoid arthritis (autoimmune). While there is no cure, treatments can significantly improve quality of life.',
      commonSymptoms: [
        'Joint pain and stiffness (worse in the morning)',
        'Swelling and redness around joints',
        'Reduced range of motion',
        'Warmth around affected joints',
        'Fatigue and general feeling of illness (rheumatoid arthritis)',
        'Crunching or grinding sensation in joints (osteoarthritis)',
      ],
      keyFact:
          'Regular low-impact exercise (swimming, walking, cycling) keeps joints mobile and reduces pain — inactivity worsens arthritis over time.',
    ),

    'osteoarthritis': DiseaseInfo(
      overview:
          'Osteoarthritis is the most common form of arthritis, affecting millions worldwide. It occurs when the protective cartilage that cushions the ends of bones wears down over time, causing bones to rub against each other. It most commonly affects the knees, hips, hands, and spine.',
      commonSymptoms: [
        'Joint pain during or after movement',
        'Stiffness (most noticeable in the morning or after rest)',
        'Loss of flexibility and range of motion',
        'Grating sensation or popping sounds during movement',
        'Bone spurs (extra bits of bone feeling like hard lumps)',
        'Swelling caused by soft tissue inflammation around the joint',
      ],
      keyFact:
          'Weight management is critical — every kilogram of excess body weight adds approximately 4 kg of pressure on each knee joint.',
    ),

    'cervical spondylosis': DiseaseInfo(
      overview:
          'Cervical spondylosis is age-related wear and tear of the cartilage and bones in the neck (cervical vertebrae). It is very common and worsens with age. Most people with cervical spondylosis experience no symptoms, but when they do occur, they usually respond well to non-surgical treatment.',
      commonSymptoms: [
        'Neck pain and stiffness',
        'Headache originating from the neck (occipital headache)',
        'Grinding or popping sensation when moving the neck',
        'Numbness or tingling in the arms, hands or fingers',
        'Muscle weakness in the arms or legs',
        'Loss of balance or coordination (if spinal cord is compressed)',
      ],
      keyFact:
          'Poor posture and prolonged screen time accelerate cervical wear — ergonomic adjustments and neck exercises are the first line of treatment.',
    ),

    // ── Neurological ─────────────────────────────────────────────────────

    'migraine': DiseaseInfo(
      overview:
          'Migraine is a complex neurological condition characterised by recurring episodes of moderate to severe headache, typically on one side of the head. Attacks often last 4–72 hours and can be accompanied by nausea, vomiting, and extreme sensitivity to light and sound. Triggers vary between individuals.',
      commonSymptoms: [
        'Intense, throbbing or pulsating headache (usually one-sided)',
        'Nausea and vomiting',
        'Extreme sensitivity to light (photophobia) and sound (phonophobia)',
        'Visual disturbances — aura (flashing lights, blind spots) before the headache',
        'Dizziness and lightheadedness',
        'Pain worsened by physical activity',
        'Fatigue and irritability before and after the attack',
      ],
      keyFact:
          'Keeping a migraine diary to identify personal triggers (e.g. certain foods, stress, hormonal changes, sleep disruption) is the most effective long-term management strategy.',
    ),

    'vertigo': DiseaseInfo(
      overview:
          'Vertigo is the sensation that the world is spinning or moving when you are still. The most common cause is Benign Paroxysmal Positional Vertigo (BPPV), caused by tiny calcium crystals that become displaced in the inner ear. It is usually harmless and often resolves with specific head-movement exercises (Epley manoeuvre).',
      commonSymptoms: [
        'Spinning or swaying sensation (even when still)',
        'Loss of balance or unsteadiness',
        'Nausea and vomiting',
        'Abnormal eye movements (nystagmus)',
        'Headache',
        'Symptoms triggered by changes in head position',
        'Feeling of fullness in the ear (if inner ear cause)',
      ],
      keyFact:
          'The Epley manoeuvre — a series of specific head and body movements — can resolve BPPV in a single treatment for most patients.',
    ),

    'paralysis (brain hemorrhage)': DiseaseInfo(
      overview:
          'A brain haemorrhage (intracranial bleeding) occurs when a blood vessel in the brain ruptures and bleeds, damaging brain tissue. It is a type of stroke and is a life-threatening emergency. Outcomes depend on the size and location of the bleed and how quickly treatment is received.',
      commonSymptoms: [
        'Sudden severe headache ("thunderclap" — worst of life)',
        'Sudden weakness or numbness on one side of the body or face',
        'Loss of speech or difficulty understanding speech',
        'Visual disturbances or loss of vision',
        'Confusion or altered consciousness',
        'Seizures',
        'Loss of balance and coordination',
        'Nausea and vomiting',
      ],
      keyFact:
          'Act FAST: Face drooping, Arm weakness, Speech difficulty, Time to call emergency services — every second counts in a stroke.',
    ),

    // ── Skin ──────────────────────────────────────────────────────────────

    'acne': DiseaseInfo(
      overview:
          'Acne is a common skin condition that occurs when hair follicles become plugged with oil and dead skin cells. It most often affects teenagers but can occur at any age. While not dangerous, it can cause significant emotional distress and permanent scarring if untreated.',
      commonSymptoms: [
        'Whiteheads (closed plugged pores)',
        'Blackheads (open plugged pores)',
        'Small red, tender bumps (papules)',
        'Pimples — papules with pus at their tips',
        'Nodules — large, solid, painful lumps under the skin',
        'Cystic lesions — painful, pus-filled lumps (most likely to scar)',
        'Skin oiliness',
      ],
      keyFact:
          'Squeezing or popping pimples significantly increases the risk of scarring — use topical benzoyl peroxide or salicylic acid instead.',
    ),

    'psoriasis': DiseaseInfo(
      overview:
          'Psoriasis is a chronic autoimmune condition that causes skin cells to multiply up to 10 times faster than normal, building up into bumpy red patches covered with white scales. It can range from mild (a few patches) to severe (covering large areas of the body). There is no cure, but effective treatments control symptoms.',
      commonSymptoms: [
        'Red patches of skin covered with thick, silvery scales',
        'Dry, cracked skin that may bleed',
        'Itching, burning or soreness',
        'Thickened, pitted or ridged nails',
        'Swollen and stiff joints (psoriatic arthritis)',
        'Symptoms that flare and then subside cyclically',
      ],
      keyFact:
          'Stress, skin injury, certain medications, and infections (especially streptococcal throat infection) are common triggers for psoriasis flares.',
    ),

    'impetigo': DiseaseInfo(
      overview:
          'Impetigo is a highly contagious bacterial skin infection most common in young children. It usually appears as reddish sores on the face, especially around the nose and mouth, and on hands and feet. The sores burst and develop honey-coloured crusts. It is easily treated with antibiotic cream or oral antibiotics.',
      commonSymptoms: [
        'Red sores that quickly rupture, ooze for a few days, then crust over',
        'Honey-coloured crusts on the face, neck, hands and nappy area',
        'Itching and sometimes soreness',
        'Blisters that burst easily leaving raw patches (bullous impetigo)',
        'Swollen lymph nodes nearby',
        'Highly contagious — spreads easily through close contact',
      ],
      keyFact:
          'Impetigo spreads easily through contact with sores or nasal discharge — children should stay home from school until 24 hours after starting antibiotics.',
    ),

    'fungal infection': DiseaseInfo(
      overview:
          'Fungal infections occur when a harmful fungus invades the body and the immune system cannot fight it off. They commonly affect the skin, nails, mouth, or genitals. Most superficial fungal infections are easily treated with topical antifungal creams or oral medication.',
      commonSymptoms: [
        'Itching and redness of the affected skin',
        'Scaly, peeling or cracking skin',
        'Ring-shaped rash with raised, scaly border (ringworm)',
        'Nail discolouration — yellow, brown or white — and thickening',
        'White patches in the mouth (oral thrush)',
        'Burning or soreness in genital area (thrush)',
        'Athlete\'s foot — scaling and blistering between toes',
      ],
      keyFact:
          'Keep skin clean and dry — fungi thrive in warm, moist environments. Avoid sharing towels, shoes or clothing.',
    ),

    // ── Renal & urinary ───────────────────────────────────────────────────

    'urinary tract infection': DiseaseInfo(
      overview:
          'A urinary tract infection (UTI) is an infection in any part of the urinary system — kidneys, bladder, ureters, or urethra. Most UTIs involve the lower urinary tract (bladder and urethra) and are more common in women. They are usually treated effectively with antibiotics.',
      commonSymptoms: [
        'Burning or painful sensation when urinating (dysuria)',
        'Frequent and urgent need to urinate with little output',
        'Cloudy, dark, or foul-smelling urine',
        'Pelvic pain (in women) or rectal pain (in men)',
        'Blood in the urine (haematuria)',
        'Fever and chills (if infection has reached the kidneys)',
        'Fatigue and general feeling of being unwell',
      ],
      keyFact:
          'Drinking plenty of water (2+ litres/day) flushes bacteria from the urinary tract and can help prevent UTIs.',
    ),

    'jaundice': DiseaseInfo(
      overview:
          'Jaundice is not a disease itself but a sign of an underlying condition causing yellowing of the skin and whites of the eyes. It occurs when the liver cannot process the yellowish pigment bilirubin fast enough, allowing it to build up in the blood. The underlying cause must be investigated and treated.',
      commonSymptoms: [
        'Yellowing of skin and whites of eyes',
        'Dark amber urine',
        'Pale or clay-coloured stools',
        'Itching (pruritus)',
        'Fatigue and weakness',
        'Abdominal pain (particularly upper right side)',
        'Weight loss and fever (if caused by infection)',
      ],
      keyFact:
          'In newborns, mild jaundice is common and usually harmless — but jaundice in adults always requires medical investigation to find the cause.',
    ),

    // ── Allergic & immune ─────────────────────────────────────────────────

    'allergy': DiseaseInfo(
      overview:
          'Allergies occur when the immune system reacts to a foreign substance (allergen) that doesn\'t cause a reaction in most people. Allergens include pollen, pet dander, certain foods, insect stings, and medications. Allergic reactions range from mild (sneezing, itching) to life-threatening (anaphylaxis).',
      commonSymptoms: [
        'Sneezing, runny or blocked nose',
        'Itchy, watery or red eyes (allergic conjunctivitis)',
        'Skin rash, hives or eczema',
        'Itching of the skin, eyes, or throat',
        'Swelling of lips, face, tongue or throat',
        'Shortness of breath or wheezing',
        'Anaphylaxis — severe, life-threatening whole-body reaction',
      ],
      keyFact:
          'Always carry an adrenaline auto-injector (EpiPen) if diagnosed with severe allergies — anaphylaxis can be fatal within minutes without treatment.',
    ),

    'drug reaction': DiseaseInfo(
      overview:
          'A drug reaction is an unwanted or harmful response to a medication, ranging from mild side effects to severe immune-mediated reactions. Adverse drug reactions are a leading cause of hospitalisation worldwide. The most serious type is anaphylaxis, which requires emergency treatment.',
      commonSymptoms: [
        'Skin rash, hives or itching',
        'Fever',
        'Swelling of the face, lips, tongue or throat',
        'Shortness of breath and wheezing',
        'Nausea, vomiting and diarrhoea',
        'Dizziness or lightheadedness',
        'Anaphylaxis (in severe reactions)',
      ],
      keyFact:
          'Always inform every healthcare provider of any drug allergies — document them clearly on your medical record to prevent future reactions.',
    ),

    // ── Other common conditions ───────────────────────────────────────────

    'anemia': DiseaseInfo(
      overview:
          'Anaemia is a condition in which there is a deficiency of red blood cells or haemoglobin in the blood, reducing the blood\'s ability to carry oxygen. Iron deficiency anaemia is the most common type worldwide. It causes fatigue, weakness, and shortness of breath. Most types respond well to treatment.',
      commonSymptoms: [
        'Fatigue, tiredness and weakness',
        'Shortness of breath on mild exertion',
        'Pale or yellowish skin',
        'Rapid or irregular heartbeat',
        'Dizziness or lightheadedness',
        'Headaches',
        'Cold hands and feet',
        'Brittle nails and inflamed tongue',
      ],
      keyFact:
          'Iron-deficiency anaemia is often caused by poor diet or blood loss — iron-rich foods (red meat, leafy greens, legumes) and vitamin C help absorption.',
    ),

    'sepsis': DiseaseInfo(
      overview:
          'Sepsis is a life-threatening emergency that occurs when the body\'s response to an infection spirals out of control, damaging its own tissues and organs. It can arise from any infection — bacterial, viral or fungal — anywhere in the body. Every hour of delay in treatment increases the risk of death.',
      commonSymptoms: [
        'High or very low body temperature (>38.5 °C or <36 °C)',
        'Rapid heart rate (>90 beats/min)',
        'Rapid breathing (>20 breaths/min)',
        'Confusion or altered mental state',
        'Extreme pain or discomfort',
        'Clammy or sweaty skin',
        'Feeling of impending doom',
        'Reduced or no urine output',
      ],
      keyFact:
          'Think SEPSIS: Shivering, Extreme pain, Pale skin, Sleepy/confused, I feel I might die, Shortness of breath — seek emergency care immediately.',
    ),

    'heat stroke': DiseaseInfo(
      overview:
          'Heat stroke is the most severe heat-related illness, occurring when the body\'s temperature regulation system fails and body temperature rises to 40 °C or higher. It is a life-threatening emergency. Without prompt cooling and emergency treatment, heat stroke can damage the brain, heart, kidneys, and muscles.',
      commonSymptoms: [
        'Body temperature 40 °C (104 °F) or higher',
        'Hot, red, dry or damp skin',
        'Rapid, strong pulse',
        'Confusion, altered behaviour, slurred speech',
        'Loss of consciousness',
        'Nausea and vomiting',
        'Headache',
        'No sweating despite the heat (classic heat stroke)',
      ],
      keyFact:
          'Move to shade, apply ice or cold water to the neck, armpits and groin, and call emergency services immediately — never leave the person alone.',
    ),

    // ── Additional diseases ───────────────────────────────────────────────

    'bronchitis': DiseaseInfo(
      overview:
          'Bronchitis is inflammation of the lining of the bronchial tubes, which carry air to and from the lungs. Acute bronchitis is usually caused by a viral infection and resolves within a few weeks. Chronic bronchitis is a more serious condition that is a component of chronic obstructive pulmonary disease (COPD).',
      commonSymptoms: [
        'Persistent cough producing mucus (clear, white, yellow or green)',
        'Shortness of breath, especially with mild exertion',
        'Wheezing or a slight whistling sound when breathing',
        'Chest tightness and discomfort',
        'Fatigue and low-grade fever',
        'Sore throat and runny nose (in acute bronchitis)',
      ],
      keyFact:
          'Most acute bronchitis is viral — antibiotics are NOT effective and should not be taken unless a bacterial cause is confirmed.',
    ),

    'sinusitis': DiseaseInfo(
      overview:
          'Sinusitis (rhinosinusitis) is inflammation of the sinuses — the hollow spaces in the skull around the nose. It is usually caused by a viral upper respiratory infection and is one of the most common reasons for GP visits. Most acute cases resolve on their own within 10 days.',
      commonSymptoms: [
        'Facial pain, pressure or fullness (especially cheeks, forehead, around eyes)',
        'Nasal congestion and thick, discoloured nasal discharge',
        'Reduced sense of smell and taste',
        'Postnasal drip causing sore throat or cough',
        'Headache that worsens when bending forward',
        'Fatigue and low-grade fever',
        'Toothache in upper teeth',
      ],
      keyFact:
          'Saline nasal irrigation (using a neti pot or saline spray) is one of the most effective non-drug treatments for relieving sinus congestion.',
    ),

    'tonsillitis': DiseaseInfo(
      overview:
          'Tonsillitis is inflammation of the tonsils, the two oval-shaped pads of tissue at the back of the throat. It is most common in children but can affect people of all ages. It can be caused by viral or bacterial infections. Bacterial tonsillitis (strep throat) requires antibiotic treatment.',
      commonSymptoms: [
        'Sore throat and pain when swallowing',
        'Red, swollen tonsils — sometimes with white or yellow patches',
        'Fever and chills',
        'Swollen lymph nodes in the neck',
        'Muffled or hoarse voice',
        'Bad breath',
        'Ear pain (referred)',
        'Loss of appetite in children',
      ],
      keyFact:
          'Streptococcal tonsillitis must be treated with antibiotics to prevent rare but serious complications such as rheumatic fever.',
    ),

    'conjunctivitis': DiseaseInfo(
      overview:
          'Conjunctivitis (pink eye) is inflammation of the conjunctiva — the thin, transparent layer that covers the white of the eye and lines the inside of the eyelid. It can be caused by viruses, bacteria, allergens, or irritants. Most infectious cases resolve on their own within 1–2 weeks.',
      commonSymptoms: [
        'Redness in the white of one or both eyes',
        'Discharge that forms a crust (especially overnight)',
        'Watery, itchy eyes (more in allergic conjunctivitis)',
        'Gritty, burning sensation in the eye',
        'Increased sensitivity to light',
        'Blurred vision',
      ],
      keyFact:
          'Bacterial conjunctivitis is highly contagious — avoid touching the eye, wash hands frequently, and do not share towels or pillowcases.',
    ),

    'kidney stones': DiseaseInfo(
      overview:
          'Kidney stones (renal calculi) are hard deposits of minerals and salts that form inside the kidneys. They can form when urine becomes too concentrated. Passing a kidney stone can be very painful but usually causes no permanent damage. Smaller stones pass on their own; larger ones may require treatment.',
      commonSymptoms: [
        'Severe, sharp pain in the back, side (flank), or lower abdomen',
        'Pain that comes in waves and fluctuates in intensity',
        'Pain that radiates to the groin',
        'Painful or burning urination',
        'Pink, red or brown urine (blood in urine)',
        'Nausea and vomiting',
        'Persistent need to urinate or urinating in small amounts',
        'Fever and chills (if infection is present)',
      ],
      keyFact:
          'Drinking 2–3 litres of water daily is the single most effective way to prevent kidney stone formation.',
    ),

    'chronic kidney disease': DiseaseInfo(
      overview:
          'Chronic kidney disease (CKD) is the gradual loss of kidney function over months or years. The kidneys filter waste and excess fluids from the blood. When CKD reaches an advanced stage, dangerous levels of fluid, electrolytes, and wastes can build up. It is most often caused by diabetes and high blood pressure.',
      commonSymptoms: [
        'Fatigue and weakness',
        'Reduced urine output or changes in urination frequency',
        'Swelling in legs, ankles and feet (oedema)',
        'Shortness of breath',
        'Nausea and loss of appetite',
        'Itching (from waste build-up in the blood)',
        'Muscle cramps and twitches',
        'High blood pressure that is difficult to control',
      ],
      keyFact:
          'CKD often has no symptoms in early stages — regular blood pressure checks and urine/blood tests are the only way to detect it early.',
    ),

    'liver cirrhosis': DiseaseInfo(
      overview:
          'Cirrhosis is late-stage liver scarring (fibrosis) caused by many forms of liver diseases and conditions — most commonly chronic alcohol use, hepatitis B, and hepatitis C. Scar tissue replaces healthy liver tissue and blocks the liver from functioning normally. It is not reversible, but further damage can be halted.',
      commonSymptoms: [
        'Fatigue and weakness',
        'Easy bruising and bleeding',
        'Jaundice (yellowing of skin and eyes)',
        'Abdominal swelling from fluid accumulation (ascites)',
        'Swelling of legs (oedema)',
        'Confusion and memory problems (hepatic encephalopathy)',
        'Spider-like blood vessels on the skin',
        'Nausea and weight loss',
      ],
      keyFact:
          'Stopping alcohol consumption, treating hepatitis B/C, and managing the underlying cause can prevent further scarring and improve survival.',
    ),

    'pancreatitis': DiseaseInfo(
      overview:
          'Pancreatitis is inflammation of the pancreas — a gland behind the stomach that makes digestive enzymes and hormones like insulin. Acute pancreatitis comes on suddenly and is usually caused by gallstones or heavy alcohol use. Chronic pancreatitis develops over time and permanently damages the pancreas.',
      commonSymptoms: [
        'Severe upper abdominal pain that may radiate to the back',
        'Pain that worsens after eating, especially fatty foods',
        'Nausea, vomiting and fever',
        'Rapid pulse',
        'Swollen and tender abdomen',
        'Unintentional weight loss (chronic pancreatitis)',
        'Oily, smelly stools (steatorrhoea) in chronic cases',
      ],
      keyFact:
          'Gallstones and alcohol are responsible for over 80% of pancreatitis cases — avoiding alcohol and treating gallstones dramatically reduces risk.',
    ),

    'irritable bowel syndrome': DiseaseInfo(
      overview:
          'Irritable bowel syndrome (IBS) is a common, long-term condition of the digestive system that causes recurring pain and altered bowel habits. It does not cause permanent damage to the gut. Triggers include stress, certain foods (particularly high-FODMAP foods), and hormonal changes. It can be managed with diet and lifestyle changes.',
      commonSymptoms: [
        'Stomach cramps and pain — often relieved by going to the toilet',
        'Bloating and excessive wind',
        'Diarrhoea, constipation, or alternating between both',
        'Feeling of incomplete emptying of bowel',
        'Mucus in stools',
        'Urgency to go to the toilet',
        'Symptoms that flare with stress or certain foods',
      ],
      keyFact:
          'A low-FODMAP diet (reducing fermentable carbohydrates like onions, garlic, wheat, and dairy) significantly reduces symptoms in 75% of IBS patients.',
    ),

    'gallstones': DiseaseInfo(
      overview:
          'Gallstones are hardened deposits of digestive fluid that can form in the gallbladder. They range from the size of a grain of sand to a golf ball. Many people have gallstones without symptoms. However, if a stone lodges in a duct and causes a blockage, the resulting pain can be severe.',
      commonSymptoms: [
        'Sudden, rapidly intensifying pain in the upper right abdomen',
        'Sudden pain in the centre of the abdomen, just below the breastbone',
        'Back pain between the shoulder blades',
        'Pain in the right shoulder',
        'Nausea and vomiting',
        'Fever and chills (if the gallbladder becomes infected)',
        'Jaundice (if a bile duct is blocked)',
      ],
      keyFact:
          'Rapid weight loss actually increases the risk of gallstones — losing weight slowly (0.5–1 kg/week) reduces this risk significantly.',
    ),

    'celiac disease': DiseaseInfo(
      overview:
          'Coeliac disease is an autoimmune condition in which eating gluten (a protein found in wheat, barley and rye) triggers an immune response that damages the small intestine lining, impairing nutrient absorption. It affects about 1% of the population. A strict lifelong gluten-free diet is the only treatment.',
      commonSymptoms: [
        'Chronic diarrhoea or constipation',
        'Abdominal pain, bloating and gas',
        'Weight loss and nutrient deficiencies',
        'Fatigue and weakness',
        'Anaemia (from iron, folate or B12 malabsorption)',
        'Bone pain and osteoporosis',
        'Itchy, blistering skin rash (dermatitis herpetiformis)',
        'Mouth ulcers and dental problems',
      ],
      keyFact:
          'Even tiny amounts of gluten (as little as crumbs on a chopping board) can trigger an immune response in people with coeliac disease.',
    ),

    'eczema': DiseaseInfo(
      overview:
          'Eczema (atopic dermatitis) is a chronic skin condition that causes the skin to become itchy, inflamed, cracked, and rough. It is particularly common in children but can occur at any age. It is not contagious. It often occurs alongside other atopic conditions such as asthma and hay fever.',
      commonSymptoms: [
        'Dry, sensitive skin',
        'Intense itching (especially at night)',
        'Red, inflamed patches of skin',
        'Small, raised bumps that weep fluid when scratched',
        'Thickened, cracked, or scaly skin',
        'Raw, swollen skin from scratching',
        'Rash in the creases of elbows, knees, wrists, and neck',
      ],
      keyFact:
          'Moisturising at least twice a day — especially immediately after bathing — is the most important thing you can do to manage eczema.',
    ),

    'shingles': DiseaseInfo(
      overview:
          'Shingles (herpes zoster) is a viral infection caused by the reactivation of the varicella-zoster virus — the same virus that causes chickenpox. After chickenpox, the virus lies dormant in nerve tissue and can reactivate decades later. Shingles is characterised by a painful rash that usually appears on one side of the body.',
      commonSymptoms: [
        'Pain, burning, or tingling that precedes the rash by 1–5 days',
        'Sensitivity to touch',
        'A red rash that appears a few days after pain begins',
        'Fluid-filled blisters that break and crust over',
        'Itching',
        'Fever, headache and fatigue',
        'Rash typically wraps around one side of the torso',
        'Rash on face (near eye) requires urgent medical attention',
      ],
      keyFact:
          'Antiviral medications (acyclovir, valacyclovir) started within 72 hours of rash onset significantly reduce pain severity and duration.',
    ),

    'cellulitis': DiseaseInfo(
      overview:
          'Cellulitis is a common bacterial skin infection that affects the deeper layers of skin (dermis and subcutaneous tissue). It usually occurs on the legs but can appear anywhere on the body. It can spread rapidly and become life-threatening if not treated promptly with antibiotics.',
      commonSymptoms: [
        'Red, swollen, warm, and tender area of skin',
        'Skin that appears taut, glossy and stretched',
        'Pain in the affected area',
        'Fever and chills',
        'Rapidly expanding area of redness',
        'Red streaks extending from the area (a sign of spreading infection)',
        'Blisters in severe cases',
      ],
      keyFact:
          'Red streaks spreading from the affected area, or fever with cellulitis, are signs of rapidly spreading infection — seek emergency care immediately.',
    ),

    'meningitis': DiseaseInfo(
      overview:
          'Meningitis is inflammation of the membranes (meninges) surrounding the brain and spinal cord. It is usually caused by a viral or bacterial infection. Bacterial meningitis is a life-threatening emergency. Viral meningitis is usually milder and resolves on its own. Vaccination provides protection against common bacterial causes.',
      commonSymptoms: [
        'Sudden high fever',
        'Severe headache that feels different from usual',
        'Stiff neck — difficulty touching chin to chest',
        'Sensitivity to light (photophobia) and sound (phonophobia)',
        'Nausea and vomiting',
        'Seizures',
        'Non-blanching purple/red rash (a sign of meningococcal septicaemia — emergency)',
        'Altered consciousness and confusion',
      ],
      keyFact:
          'The glass test: if a rash does not fade when pressed with a glass tumbler, this may be meningococcal disease — call emergency services immediately.',
    ),

    'epilepsy': DiseaseInfo(
      overview:
          'Epilepsy is a neurological disorder in which brain activity becomes abnormal, causing seizures. Seizures are sudden surges of electrical activity in the brain that affect behaviour, movements, feelings, or consciousness. Epilepsy can be managed with medications (antiseizure drugs) in about 70% of people.',
      commonSymptoms: [
        'Temporary confusion and "staring spell"',
        'Uncontrollable jerking movements of the arms and legs',
        'Loss of consciousness and awareness',
        'Stiffening of the body',
        'Psychic symptoms — fear, anxiety, or déjà vu',
        'Brief blackouts or periods of memory loss',
        'Falls without apparent cause',
      ],
      keyFact:
          'During a seizure: stay with the person, protect them from injury, time the seizure — call an ambulance if it lasts longer than 5 minutes or the person does not recover.',
    ),

    'carpal tunnel syndrome': DiseaseInfo(
      overview:
          'Carpal tunnel syndrome (CTS) occurs when the median nerve — which runs from the forearm through the carpal tunnel in the wrist to the hand — becomes compressed. It is the most common peripheral nerve disorder. Risk factors include repetitive hand use, wrist injuries, and certain medical conditions including diabetes and rheumatoid arthritis.',
      commonSymptoms: [
        'Numbness and tingling in the thumb, index, middle and ring fingers',
        'Electric shock-like sensations that may radiate up the arm',
        'Weakness in the grip — tendency to drop objects',
        'Symptoms worse at night or early morning',
        'Pain in the wrist and hand',
        'Symptoms relieved by shaking the hand (Flick sign)',
      ],
      keyFact:
          'Wearing a wrist splint at night keeps the wrist in a neutral position and often relieves nocturnal symptoms without surgery.',
    ),

    'osteoporosis': DiseaseInfo(
      overview:
          'Osteoporosis is a condition that weakens bones, making them fragile and more likely to break. It develops slowly over several years and is often only diagnosed after a fracture. It is most common in post-menopausal women and older adults. Adequate calcium, vitamin D, and regular weight-bearing exercise reduce the risk.',
      commonSymptoms: [
        'Often no symptoms until a fracture occurs ("silent disease")',
        'Back pain (caused by fractured or collapsed vertebra)',
        'Loss of height over time',
        'Stooped posture (kyphosis)',
        'Bone fractures that occur far more easily than expected',
        'Fractures most common in the hip, wrist, and spine',
      ],
      keyFact:
          'A DEXA scan (bone density test) is the definitive test — post-menopausal women and men over 70 should discuss screening with their doctor.',
    ),

    'fibromyalgia': DiseaseInfo(
      overview:
          'Fibromyalgia is a chronic condition characterised by widespread musculoskeletal pain, fatigue, sleep, memory and mood issues. It is thought to amplify painful sensations by affecting the way the brain and spinal cord process pain signals. There is no cure, but symptoms can be managed with medication, exercise, and stress reduction.',
      commonSymptoms: [
        'Widespread muscle pain and aching throughout the body',
        'Fatigue — even after long periods of sleep',
        'Sleep problems — waking up unrefreshed',
        'Cognitive difficulties — "fibro fog" (memory and concentration problems)',
        'Headaches, including migraines',
        'Irritable bowel syndrome (IBS)',
        'Increased sensitivity to pain, heat, cold, and light',
      ],
      keyFact:
          'Regular aerobic exercise (swimming, walking, cycling) is the most effective single intervention for reducing fibromyalgia pain and fatigue.',
    ),

    'lupus': DiseaseInfo(
      overview:
          'Lupus (systemic lupus erythematosus, SLE) is a chronic autoimmune disease in which the immune system attacks healthy tissue in many parts of the body. It can affect the skin, joints, kidneys, brain, heart, and lungs. Lupus flares unpredictably; periods of illness alternate with periods of remission.',
      commonSymptoms: [
        'Butterfly-shaped rash on the face (across the cheeks and nose)',
        'Fatigue and fever',
        'Joint pain, stiffness and swelling',
        'Sensitivity to sunlight (photosensitivity)',
        'Fingers and toes turning white or blue in cold temperatures (Raynaud\'s)',
        'Shortness of breath and chest pain',
        'Dry eyes and hair loss',
        'Headaches and confusion',
      ],
      keyFact:
          'Sunscreen and sun-protective clothing are essential for people with lupus — UV exposure frequently triggers flares.',
    ),

    'otitis media': DiseaseInfo(
      overview:
          'Otitis media is a middle ear infection — infection and inflammation of the space behind the eardrum. It is one of the most common childhood illnesses, but it can also affect adults. Most acute cases are caused by bacteria or viruses following an upper respiratory infection and resolve within a few weeks.',
      commonSymptoms: [
        'Ear pain (especially when lying down)',
        'Tugging or pulling at the ear (in young children)',
        'Difficulty hearing',
        'Fluid drainage from the ear',
        'Fever',
        'Irritability and crying in infants',
        'Difficulty sleeping',
        'Headache and loss of appetite',
      ],
      keyFact:
          'Children with frequent ear infections may benefit from ventilation tubes (grommets) — discuss with your doctor if there have been 3+ infections in 6 months.',
    ),

    'depression': DiseaseInfo(
      overview:
          'Depression (major depressive disorder) is a common and serious medical illness that negatively affects how you feel, think, and act. It causes feelings of sadness and a loss of interest in activities once enjoyed. It is a genuine medical condition — not a weakness — and is very treatable with therapy and/or medication.',
      commonSymptoms: [
        'Persistent sad, anxious or "empty" mood',
        'Loss of interest or pleasure in activities once enjoyed (anhedonia)',
        'Feelings of hopelessness, worthlessness, or guilt',
        'Fatigue and decreased energy',
        'Difficulty sleeping or sleeping too much',
        'Changes in appetite — weight loss or gain',
        'Difficulty thinking, concentrating or making decisions',
        'Thoughts of death or suicide',
      ],
      keyFact:
          'Depression is treatable in over 80% of cases — effective treatments include talking therapies (CBT) and antidepressant medications.',
    ),

    'anxiety disorder': DiseaseInfo(
      overview:
          'Anxiety disorders are a group of mental health conditions characterised by excessive, persistent worry or fear that is difficult to control and interferes with daily activities. They are the most common mental health disorders worldwide. Effective treatments include cognitive-behavioural therapy (CBT) and medication.',
      commonSymptoms: [
        'Excessive worry that is difficult to control',
        'Restlessness, feeling on edge or keyed up',
        'Fatigue and muscle tension',
        'Difficulty concentrating — mind goes blank',
        'Irritability',
        'Sleep disturbances — difficulty falling or staying asleep',
        'Physical symptoms: racing heart, sweating, trembling, shortness of breath',
      ],
      keyFact:
          'Controlled breathing (4-7-8 technique: inhale 4 sec, hold 7 sec, exhale 8 sec) activates the parasympathetic nervous system and quickly reduces acute anxiety.',
    ),

    'scabies': DiseaseInfo(
      overview:
          'Scabies is a highly contagious skin infestation caused by a tiny mite called Sarcoptes scabiei. The mites burrow into the skin and lay eggs, causing an intensely itchy rash. It spreads easily through skin-to-skin contact and is common in crowded living conditions. It is effectively treated with prescription topical creams.',
      commonSymptoms: [
        'Intense itching that is much worse at night',
        'Thin, irregular burrow tracks (wavy lines) in the skin',
        'Pimple-like rash with small blisters or scales',
        'Most common in the finger webs, wrists, armpits, waistline, and genitals',
        'Sores from scratching that can become infected',
        'Crusted (Norwegian) scabies in people with weakened immunity — thick, grey crusts',
      ],
      keyFact:
          'All household members and close contacts must be treated simultaneously — even if they have no symptoms — to prevent reinfection.',
    ),

    'pleurisy': DiseaseInfo(
      overview:
          'Pleurisy (pleuritis) is inflammation of the pleura — the two-layered membrane that surrounds the lungs and lines the chest cavity. When these layers become inflamed, they rub against each other like two pieces of sandpaper, causing sharp chest pain. It is most often caused by a viral infection.',
      commonSymptoms: [
        'Sharp, stabbing chest pain that worsens with breathing, coughing or sneezing',
        'Pain that may radiate to the shoulder or back',
        'Shortness of breath as you take shallow breaths to avoid pain',
        'A dry cough',
        'Fever (if caused by infection)',
        'A clicking, rasping sound when the doctor listens to the lungs (pleural rub)',
      ],
      keyFact:
          'Lying on the painful side actually splints the chest and can reduce pain while you rest — anti-inflammatory medications (NSAIDs) are the first-line treatment.',
    ),

    'hernia': DiseaseInfo(
      overview:
          'A hernia occurs when an internal organ or fatty tissue squeezes through a weak spot in the surrounding muscle or connective tissue. The most common type is an inguinal (inner groin) hernia. Hernias are usually not immediately dangerous but do not go away on their own — surgery may be needed.',
      commonSymptoms: [
        'A visible bulge in the abdomen, groin or scrotum',
        'Aching or burning sensation at the bulge site',
        'Discomfort or pain when bending over, coughing or lifting',
        'Weakness, pressure or heaviness in the abdomen',
        'Nausea and vomiting (in strangulated hernia — emergency)',
        'Sudden severe pain with inability to push bulge back in (strangulated — emergency)',
      ],
      keyFact:
          'A strangulated hernia — where blood supply to the trapped tissue is cut off — is a surgical emergency. Sudden severe pain, fever, and inability to reduce the hernia require immediate hospital care.',
    ),

    'polycystic ovary syndrome': DiseaseInfo(
      overview:
          'Polycystic ovary syndrome (PCOS) is a hormonal disorder common among women of reproductive age. Women with PCOS may have infrequent or prolonged menstrual periods or excess androgen (male hormone) levels. The ovaries may develop small collections of fluid (follicles). PCOS is a leading cause of female infertility.',
      commonSymptoms: [
        'Irregular periods — infrequent, irregular, or prolonged menstrual cycles',
        'Excess androgen — elevated levels causing facial and body hair (hirsutism)',
        'Acne on the face, chest and upper back',
        'Thinning hair and male-pattern baldness',
        'Polycystic ovaries visible on ultrasound',
        'Weight gain and difficulty losing weight',
        'Skin darkening in body creases (acanthosis nigricans)',
      ],
      keyFact:
          'Losing even 5–10% of body weight can significantly improve hormonal balance, restore regular periods, and increase fertility in women with PCOS.',
    ),

    'tinnitus': DiseaseInfo(
      overview:
          'Tinnitus is the perception of noise or ringing in the ears when no external sound is present. It is a symptom, not a disease itself, and can be caused by hearing loss, ear injury, or a circulatory system disorder. It affects about 15–20% of people and is especially common in older adults.',
      commonSymptoms: [
        'Ringing, buzzing, roaring, clicking, hissing or humming in the ears',
        'Sound that may be in one or both ears, or seem to come from inside the head',
        'Sound that may be constant or intermittent',
        'Varying pitch — from low to high frequency',
        'Sleep disturbances and concentration difficulties',
        'Associated hearing loss',
        'Stress and anxiety from the constant noise',
      ],
      keyFact:
          'Avoiding loud noise and using hearing protection are the most effective ways to prevent tinnitus — once hearing damage occurs, it cannot be reversed.',
    ),

    'glaucoma': DiseaseInfo(
      overview:
          'Glaucoma is a group of eye conditions that damage the optic nerve, usually due to abnormally high pressure in the eye. It is one of the leading causes of blindness worldwide. Most forms develop slowly with no early symptoms, which is why regular eye check-ups are essential for early detection.',
      commonSymptoms: [
        'Gradual loss of peripheral (side) vision — often in both eyes',
        'Tunnel vision in advanced stages',
        'Sudden eye pain (acute angle-closure glaucoma)',
        'Headache, nausea and vomiting (acute type)',
        'Blurred vision and halos around lights (acute type)',
        'Redness of the eye',
        'Open-angle type: usually no symptoms until significant vision is lost',
      ],
      keyFact:
          'Regular comprehensive eye exams are the only way to detect open-angle glaucoma early — vision lost to glaucoma cannot be restored.',
    ),

    'rheumatoid arthritis': DiseaseInfo(
      overview:
          'Rheumatoid arthritis (RA) is a chronic autoimmune disorder that primarily affects joints. Unlike the wear-and-tear damage of osteoarthritis, RA attacks the lining of the joints (synovium), causing painful swelling that can eventually result in bone erosion and joint deformity. It can also damage the heart, lungs, and blood vessels.',
      commonSymptoms: [
        'Tender, warm, swollen joints — usually affecting small joints first (fingers, wrists)',
        'Joint stiffness worse in the morning (lasting more than 30 minutes)',
        'Fatigue, fever and loss of appetite',
        'Symmetrical pattern — same joints on both sides of the body',
        'Rheumatoid nodules — firm lumps under the skin',
        'Worsening symptoms during "flares" alternating with periods of remission',
      ],
      keyFact:
          'Early aggressive treatment with disease-modifying drugs (DMARDs) within the first few months prevents permanent joint damage and disability.',
    ),

    'benign prostatic hyperplasia': DiseaseInfo(
      overview:
          'Benign prostatic hyperplasia (BPH) is a noncancerous enlargement of the prostate gland that is very common as men age. An enlarged prostate gland can cause uncomfortable urinary symptoms, such as blocking urine flow out of the bladder. It is not prostate cancer and does not increase the risk of developing it.',
      commonSymptoms: [
        'Frequent or urgent need to urinate',
        'Increased frequency of urination at night (nocturia)',
        'Difficulty starting urination',
        'Weak urine stream or a stream that stops and starts',
        'Dribbling at the end of urination',
        'Inability to completely empty the bladder',
        'Urinary tract infection',
      ],
      keyFact:
          'Caffeine and alcohol can worsen BPH symptoms by increasing urine production and bladder irritation — reducing intake often brings significant relief.',
    ),

    'anorexia nervosa': DiseaseInfo(
      overview:
          'Anorexia nervosa is a serious eating disorder characterised by abnormally low body weight, intense fear of gaining weight, and a distorted perception of weight or shape. People with anorexia place a high value on controlling their weight and shape, using extreme efforts that tend to significantly interfere with their lives and health.',
      commonSymptoms: [
        'Extremely restricted eating and intense fear of weight gain',
        'Very low body weight relative to age and height',
        'Distorted body image — seeing oneself as fat despite being underweight',
        'Fatigue, dizziness and fainting',
        'Thin, brittle bones (osteoporosis) and easily fractured bones',
        'Fine hair all over the body (lanugo)',
        'Absent menstrual periods in women',
        'Constipation, cold intolerance, and low blood pressure',
      ],
      keyFact:
          'Anorexia nervosa has the highest mortality rate of any mental health disorder — early intervention dramatically improves outcomes.',
    ),

    'ménière\'s disease': DiseaseInfo(
      overview:
          'Ménière\'s disease is a disorder of the inner ear that causes episodes of vertigo (spinning dizziness), hearing loss, tinnitus (ringing in the ear), and a feeling of fullness in the ear. The cause is thought to be abnormal fluid build-up in the inner ear. Attacks are unpredictable and can significantly affect quality of life.',
      commonSymptoms: [
        'Episodes of vertigo — spinning sensation that starts and stops spontaneously',
        'Hearing loss — initially fluctuating, may become permanent over time',
        'Tinnitus — ringing, buzzing, roaring or hissing in the ear',
        'Feeling of fullness or pressure in the ear',
        'Nausea and vomiting during attacks',
        'Sudden falls without loss of consciousness (drop attacks)',
      ],
      keyFact:
          'Reducing salt intake to less than 1500 mg per day can significantly reduce fluid retention in the inner ear and frequency of attacks.',
    ),

    'plantar fasciitis': DiseaseInfo(
      overview:
          'Plantar fasciitis is the most common cause of heel pain. It involves inflammation of the plantar fascia — a thick band of tissue that runs across the bottom of the foot, connecting the heel bone to the toes. It is especially common in runners, overweight individuals, and people who wear shoes with inadequate support.',
      commonSymptoms: [
        'Stabbing pain in the bottom of the foot near the heel',
        'Pain that is worst with the first few steps in the morning',
        'Pain that returns after long periods of standing or after sitting then rising',
        'Pain after (not usually during) exercise',
        'Stiffness in the bottom of the foot',
        'Tenderness when pressing on the heel',
      ],
      keyFact:
          'Most cases resolve within 10 months with stretching exercises, supportive footwear, and ice — the key stretches target the plantar fascia and Achilles tendon.',
    ),

    'multiple sclerosis': DiseaseInfo(
      overview:
          'Multiple sclerosis (MS) is a potentially disabling disease of the brain and spinal cord. The immune system attacks the protective sheath (myelin) that covers nerve fibres, causing communication problems between the brain and the rest of the body. Symptoms vary widely and most people experience relapses followed by periods of partial or complete recovery.',
      commonSymptoms: [
        'Numbness or weakness in one or more limbs, typically on one side',
        'Tingling, pain or electric shock sensations with neck movement (Lhermitte\'s sign)',
        'Vision problems — blurred vision, double vision, or loss of vision',
        'Fatigue (often the most disabling symptom)',
        'Dizziness and problems with balance and coordination',
        'Slurred speech and tremor',
        'Bladder and bowel dysfunction',
        'Cognitive changes — memory and concentration problems',
      ],
      keyFact:
          'Regular exercise, vitamin D supplementation, and not smoking all reduce the risk of MS relapses and slow disease progression.',
    ),

    'stroke': DiseaseInfo(
      overview:
          'A stroke occurs when the blood supply to part of the brain is cut off. Without blood, brain cells begin to die. There are two main types: ischaemic stroke (caused by a blood clot) and haemorrhagic stroke (caused by bleeding in the brain). It is a medical emergency — fast treatment can limit brain damage and potential complications.',
      commonSymptoms: [
        'Face drooping — one side of the face droops or is numb',
        'Arm weakness — one arm is weak or numb and drifts down when raised',
        'Speech difficulty — slurred, strange, or unable to speak',
        'Sudden severe headache with no known cause',
        'Sudden confusion or trouble understanding speech',
        'Sudden vision problems in one or both eyes',
        'Sudden loss of balance or coordination',
      ],
      keyFact:
          'Act FAST — Face, Arms, Speech, Time. Call emergency services immediately. Every minute saved preserves 1.9 million brain cells.',
    ),

    'leptospirosis': DiseaseInfo(
      overview:
          'Leptospirosis is a bacterial infection caused by Leptospira bacteria, spread through the urine of infected animals (especially rats) in contaminated water or soil. It is common after floods and in tropical regions. Mild cases resemble influenza; severe Weil\'s disease can cause organ failure and is life-threatening.',
      commonSymptoms: [
        'High fever and severe headache',
        'Muscle pain and aches (particularly in the calves)',
        'Chills and red eyes',
        'Nausea, vomiting and diarrhoea',
        'Skin rash',
        'Jaundice (in severe Weil\'s disease)',
        'Kidney failure and bleeding (in severe cases)',
      ],
      keyFact:
          'Wearing protective footwear and avoiding contact with floodwater are the most effective preventions — post-flood seasons in tropical areas carry high risk.',
    ),

    'ross river fever': DiseaseInfo(
      overview:
          'Ross River fever is a viral disease spread by mosquito bites in Australia. It cannot be spread from person to person. Most people recover within weeks to months, but some experience prolonged joint pain and fatigue. There is no vaccine or specific treatment — management focuses on relieving symptoms.',
      commonSymptoms: [
        'Joint pain, stiffness and swelling — often in the wrists, knees, ankles and fingers',
        'Rash on the trunk, limbs or face (often pinkish-red spots)',
        'Fatigue and muscle aches',
        'Fever (not always present)',
        'Headache',
        'Symptoms that may persist for months and fluctuate',
      ],
      keyFact:
          'Ross River fever is prevalent in northern and eastern Australia — long sleeves, insect repellent, and eliminating mosquito breeding sites near homes reduce risk.',
    ),

    'whooping cough': DiseaseInfo(
      overview:
          'Whooping cough (pertussis) is a highly contagious respiratory tract infection caused by the bacterium Bordetella pertussis. It is recognised by the severe hacking cough followed by a high-pitched intake of breath ("whoop"). It is most dangerous in infants and can be fatal. Vaccination is the best prevention.',
      commonSymptoms: [
        'Runny nose, nasal congestion and mild fever (early stage)',
        'Severe coughing fits lasting 1–6 weeks',
        'High-pitched "whoop" sound during inhalation after coughing',
        'Vomiting after coughing fits',
        'Exhaustion after coughing episodes',
        'In infants: apnoea (pause in breathing) instead of the whoop',
        'Coughing so hard that it causes bruised ribs, fainting, or vomiting',
      ],
      keyFact:
          'The whooping cough vaccine loses effectiveness over time — adults (especially those in contact with infants) should receive a booster dose.',
    ),

    'worms': DiseaseInfo(
      overview:
          'Intestinal worm infections (helminths) are caused by parasitic worms including roundworms, hookworms, tapeworms, pinworms, and threadworms. They are very common in tropical and remote areas with poor sanitation. Most respond well to a single dose of antiparasitic medication.',
      commonSymptoms: [
        'Abdominal pain or tenderness',
        'Nausea, diarrhoea or vomiting',
        'Intense anal itching — especially at night (pinworms/threadworms)',
        'Fatigue and weakness',
        'Weight loss and poor appetite',
        'Visible worms in stools',
        'Iron-deficiency anaemia (hookworm)',
        'Failure to thrive in children',
      ],
      keyFact:
          'Washing hands with soap before eating and after using the toilet, and wearing shoes outdoors, are the most effective preventions in endemic areas.',
    ),
  };
}
