package Demo;

import javax.swing.*;
import java.awt.*;

public class AnalysisPanel extends JPanel {

    private SmartAdaptiveClinicalAssistant mainFrame;

    public AnalysisPanel(SmartAdaptiveClinicalAssistant frame, String result) {
        this.mainFrame = frame;
        setBackground(Color.WHITE);
        setLayout(new BorderLayout(10, 10));
        setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // 顶部
        JLabel title = new JLabel("Triage Analysis", SwingConstants.CENTER);
        title.setFont(new Font("Arial", Font.BOLD, 24));
        add(title, BorderLayout.NORTH);

        // 中间
        JPanel centerPanel = new JPanel();
        centerPanel.setLayout(new BoxLayout(centerPanel, BoxLayout.Y_AXIS));
        centerPanel.setBackground(Color.WHITE);
        centerPanel.setBorder(BorderFactory.createEmptyBorder(30, 50, 30, 50));

        JLabel resultLabel = new JLabel("Patient Report:");
        resultLabel.setFont(new Font("Arial", Font.BOLD, 16));
        resultLabel.setAlignmentX(Component.LEFT_ALIGNMENT);

        JTextArea resultArea = new JTextArea(result);
        resultArea.setFont(new Font("Arial", Font.PLAIN, 15));
        resultArea.setEditable(false);
        resultArea.setBackground(new Color(245, 248, 250));
        resultArea.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));
        resultArea.setAlignmentX(Component.LEFT_ALIGNMENT);

        JLabel triageLabel = new JLabel("Triage Level: NON-URGENT");
        triageLabel.setFont(new Font("Arial", Font.BOLD, 18));
        triageLabel.setForeground(new Color(0, 150, 0));
        triageLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
        triageLabel.setBorder(BorderFactory.createEmptyBorder(20, 0, 0, 0));

        JLabel adviceLabel = new JLabel("<html>Recommendation:<br>Schedule appointment within 24-48 hours.</html>");
        adviceLabel.setFont(new Font("Arial", Font.PLAIN, 14));
        adviceLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
        adviceLabel.setBorder(BorderFactory.createEmptyBorder(10, 0, 0, 0));

        centerPanel.add(resultLabel);
        centerPanel.add(Box.createVerticalStrut(10));
        centerPanel.add(resultArea);
        centerPanel.add(triageLabel);
        centerPanel.add(adviceLabel);

        add(centerPanel, BorderLayout.CENTER);

        // 底部
        JPanel bottomPanel = new JPanel(new FlowLayout(FlowLayout.CENTER));
        bottomPanel.setBackground(Color.WHITE);

        JButton homeBtn = new JButton("Finish → Home");
        homeBtn.setFont(new Font("Arial", Font.BOLD, 16));
        homeBtn.setPreferredSize(new Dimension(180, 45));
        homeBtn.addActionListener(e -> mainFrame.showHome());

        bottomPanel.add(homeBtn);
        add(bottomPanel, BorderLayout.SOUTH);
    }
}