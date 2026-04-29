package Demo;

import javax.swing.*;
import java.awt.*;
import java.util.ArrayList;
import java.util.List;

public class SymptomPanel extends JPanel {

    private SmartAdaptiveClinicalAssistant mainFrame;
    private String bodyPart;
    private List<JCheckBox> checkBoxes = new ArrayList<>();

    public SymptomPanel(SmartAdaptiveClinicalAssistant frame, String bodyPart) {
        this.mainFrame = frame;
        this.bodyPart = bodyPart;
        setBackground(Color.WHITE);
        setLayout(new BorderLayout(10, 10));
        setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // 顶部
        JPanel topPanel = new JPanel(new BorderLayout());
        topPanel.setBackground(Color.WHITE);

        JButton backBtn = new JButton("← Back");
        backBtn.setFont(new Font("Arial", Font.PLAIN, 14));
        backBtn.addActionListener(e -> {
            mainFrame.getContentPane().removeAll();
            mainFrame.getContentPane().add(new SelectionPanel(mainFrame));
            mainFrame.revalidate();
            mainFrame.repaint();
        });
        topPanel.add(backBtn, BorderLayout.WEST);

        JLabel title = new JLabel(bodyPart + " Symptoms", SwingConstants.CENTER);
        title.setFont(new Font("Arial", Font.BOLD, 22));
        topPanel.add(title, BorderLayout.CENTER);

        add(topPanel, BorderLayout.NORTH);

        // 中间：症状复选框
        JPanel symptomPanel = new JPanel();
        symptomPanel.setLayout(new BoxLayout(symptomPanel, BoxLayout.Y_AXIS));
        symptomPanel.setBackground(Color.WHITE);
        symptomPanel.setBorder(BorderFactory.createEmptyBorder(30, 80, 30, 80));

        JLabel prompt = new JLabel("Select all that apply:");
        prompt.setFont(new Font("Arial", Font.BOLD, 16));
        prompt.setAlignmentX(Component.LEFT_ALIGNMENT);
        symptomPanel.add(prompt);
        symptomPanel.add(Box.createVerticalStrut(20));

        String[] symptoms = getSymptoms(bodyPart);
        for (String symptom : symptoms) {
            JCheckBox cb = new JCheckBox(symptom);
            cb.setFont(new Font("Arial", Font.PLAIN, 16));
            cb.setBackground(Color.WHITE);
            cb.setAlignmentX(Component.LEFT_ALIGNMENT);
            symptomPanel.add(cb);
            symptomPanel.add(Box.createVerticalStrut(10));
            checkBoxes.add(cb);
        }

        add(symptomPanel, BorderLayout.CENTER);

        // 底部：确认按钮
        JPanel bottomPanel = new JPanel(new FlowLayout(FlowLayout.CENTER));
        bottomPanel.setBackground(Color.WHITE);

        JButton confirmBtn = new JButton("Confirm & Analyze");
        confirmBtn.setFont(new Font("Arial", Font.BOLD, 16));
        confirmBtn.setBackground(new Color(41, 98, 255));
        confirmBtn.setForeground(Color.WHITE);
        confirmBtn.setPreferredSize(new Dimension(200, 45));
        confirmBtn.addActionListener(e -> {
            // 收集选中的症状
            StringBuilder selected = new StringBuilder();
            for (JCheckBox cb : checkBoxes) {
                if (cb.isSelected()) {
                    selected.append(cb.getText()).append(", ");
                }
            }
            if (selected.length() == 0) {
                JOptionPane.showMessageDialog(this, "Please select at least one symptom.");
                return;
            }

            // 跳转到分析页
            String result = "Body Part: " + bodyPart + "\nSymptoms: " + selected.toString();
            mainFrame.getContentPane().removeAll();
            mainFrame.getContentPane().add(new AnalysisPanel(mainFrame, result));
            mainFrame.revalidate();
            mainFrame.repaint();
        });

        bottomPanel.add(confirmBtn);
        add(bottomPanel, BorderLayout.SOUTH);
    }

    private String[] getSymptoms(String part) {
        switch (part) {
            case "Head":
                return new String[]{"Headache", "Dizziness", "Eye pain", "Ear pain", "Facial pain", "Toothache"};
            case "Chest":
                return new String[]{"Chest pain", "Tightness", "Palpitations", "Difficulty breathing", "Cough"};
            case "Stomach":
                return new String[]{"Stomach ache", "Nausea", "Bloating", "Heartburn", "Diarrhea", "Constipation"};
            case "Back":
                return new String[]{"Upper back pain", "Lower back pain", "Muscle spasm", "Stiffness", "Radiating pain"};
            case "Arms":
                return new String[]{"Arm pain", "Swelling", "Numbness", "Weakness", "Joint pain"};
            case "Legs":
                return new String[]{"Leg pain", "Swelling", "Cramps", "Numbness", "Joint pain", "Varicose veins"};
            default:
                return new String[]{"Pain", "Discomfort", "Swelling"};
        }
    }
}